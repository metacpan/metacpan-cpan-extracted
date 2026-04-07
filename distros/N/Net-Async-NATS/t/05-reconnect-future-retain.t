use strict;
use warnings;
use Test2::V0;

use IO::Async::Loop;
use IO::Async::Listener;
use Net::Async::NATS;
use JSON::MaybeXS qw(encode_json);

# Regression test: the reconnect path must hold the connect Future
# somewhere persistent. Previously, _reconnect stored the Future only
# in a closure variable, so the async sub connect() was garbage-collected
# mid-flight, producing:
#   "Suspended async sub Net::Async::NATS::connect lost its returning future"

my $loop = IO::Async::Loop->new;

# Fake NATS server that sends INFO on every new connection.
# Keeps track of the current client stream so the test can force a
# disconnect and observe the reconnect path.
my $server_port;
my $connection_count = 0;
my $current_stream;

my $listener = IO::Async::Listener->new(
    on_stream => sub {
        my ($self, $stream) = @_;
        $connection_count++;
        $current_stream = $stream;

        $stream->configure(
            on_read => sub {
                my ($self, $buffref, $eof) = @_;
                if ($$buffref =~ s/\APING\r\n//) {
                    $self->write("PONG\r\n");
                }
                $$buffref = '';
                return 0;
            },
        );
        $loop->add($stream);

        my $info = encode_json({
            server_id   => 'TEST_RECONNECT',
            version     => '0.0.0',
            proto       => 1,
            host        => '0.0.0.0',
            port        => $server_port,
            max_payload => 1048576,
        });
        $stream->write("INFO $info\r\n");
    },
);
$loop->add($listener);
$listener->listen(
    addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 },
)->get;
$server_port = $listener->read_handle->sockport;

note "Fake NATS server on port $server_port";

# Track warnings so we can assert "lost its returning future" never appears
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $disconnect_count = 0;
my $reconnect_done   = $loop->new_future;

my $nats = Net::Async::NATS->new(
    host                   => '127.0.0.1',
    port                   => $server_port,
    name                   => 'test-reconnect',
    reconnect              => 1,
    reconnect_wait         => 0,     # no delay — fire immediately
    max_reconnect_attempts => 3,
    on_disconnect          => sub {
        my ($self, $reason) = @_;
        $disconnect_count++;
    },
    on_connect             => sub {
        my ($self, $info) = @_;
        # Signal that the second (reconnected) connection is up
        $reconnect_done->done($info) if $connection_count >= 2 && !$reconnect_done->is_ready;
    },
);
$loop->add($nats);

# Initial connect
my $info = $nats->connect->get;
is $info->{server_id}, 'TEST_RECONNECT', 'initial connect ok';
is $connection_count, 1, 'server saw one connection';
ok $nats->is_connected, 'client reports connected';

# Force a disconnect by closing the server's view of the client stream
ok $current_stream, 'have reference to server-side client stream';
$current_stream->close_now;
undef $current_stream;

# Give the loop a chance to notice the EOF and run the reconnect chain
my $timeout_f = $loop->delay_future(after => 5)
    ->then_fail('reconnect did not complete within 5s');

my $reinfo = eval { $loop->await(Future->wait_any($reconnect_done, $timeout_f)) };
my $err = $@;

ok !$err, 'reconnect completed without timeout'
    or diag "Error: $err";
is $disconnect_count, 1, 'on_disconnect fired exactly once';
is $connection_count, 2, 'server saw a reconnect';
ok $nats->is_connected, 'client reports connected after reconnect';

# The big one: no "lost its returning future" warning from Future::AsyncAwait
my @lost = grep { /lost its returning future/ } @warnings;
is scalar(@lost), 0, 'no "lost returning future" warnings during reconnect'
    or diag "Warnings:\n" . join("\n", @warnings);

# Clean up
eval { $loop->await($nats->disconnect) };

done_testing;
