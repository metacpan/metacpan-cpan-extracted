use strict;
use warnings;
use Test2::V0;

use IO::Async::Loop;
use IO::Async::Listener;
use Net::Async::NATS;
use JSON::MaybeXS qw(encode_json);

# This test verifies that the TCP connect Future is retained during the
# NATS handshake.  Without retention the Future gets garbage-collected,
# on_read never fires, and connect() hangs forever.

my $loop = IO::Async::Loop->new;

# Spin up a minimal fake NATS server that sends INFO + accepts CONNECT
my $server_port;
my $listener = IO::Async::Listener->new(
    on_stream => sub {
        my ($self, $stream) = @_;
        $stream->configure(
            on_read => sub {
                my ($self, $buffref, $eof) = @_;
                # Consume and ignore client data (CONNECT, PING, etc.)
                if ($$buffref =~ s/\APING\r\n//) {
                    $self->write("PONG\r\n");
                }
                $$buffref = '';
                return 0;
            },
        );
        $loop->add($stream);

        # Send INFO immediately like a real NATS server
        my $info = encode_json({
            server_id   => 'TEST_FAKE',
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

# Now connect with Net::Async::NATS and verify it completes
my $nats = Net::Async::NATS->new(
    host      => '127.0.0.1',
    port      => $server_port,
    name      => 'test-retain',
    reconnect => 0,
);
$loop->add($nats);

# Use a timeout to detect the hang (the bug this test guards against)
my $connect_f = $nats->connect;
my $timeout_f = $loop->delay_future(after => 3)->then_fail('connect timed out — Future likely GC\'d');

my $info = eval { $loop->await(Future->wait_any($connect_f, $timeout_f)) };
my $err = $@;

ok !$err, 'connect completed without timeout'
    or diag "Error: $err";
ok $nats->is_connected, 'client reports connected';
is $nats->server_info->{server_id}, 'TEST_FAKE', 'received server INFO';

# Clean up
eval { $loop->await($nats->disconnect) };

done_testing;
