use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# Destroying a session frees the data providers it still owns. Freeing one
# drops the last reference to its callback_data, so that object's DESTROY runs
# - arbitrary Perl - in the middle of session teardown. The guard-that-flushes
# pattern of t/31 calls back into the session it holds a weak reference to, and
# a weak reference is still live while its referent's own destructor runs. The
# nghttp2 handle is gone by then, so the method must refuse rather than
# dereference a deleted session.

my $destroyed = 0;
my @reentry_results;

{
    package Test::Teardown::Guard;
    use Scalar::Util qw(weaken);

    sub new {
        my ($class, %args) = @_;
        my $self = bless { %args }, $class;
        weaken($self->{session});
        return $self;
    }

    sub DESTROY {
        my ($self) = @_;
        return if $self->{destroyed}++;
        $self->{on_destroy}->($self->{session});
        return;
    }
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my @server_streams;
my ($client, $server) = new_session_pair(
    server_callbacks => {
        on_frame_recv => sub {
            my ($frame) = @_;
            push @server_streams, $frame->{stream_id}
                if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
            return 0;
        },
    },
);

$client->submit_request(
    method    => 'GET',
    scheme    => 'https',
    authority => 'example.test',
    path      => '/held-open',
);
pump_sessions($client, $server);
is(scalar @server_streams, 1, 'the server received the request');

# A body callback that always defers keeps the stream open, so the provider is
# still registered with the session when the session is destroyed.
$server->submit_response(
    $server_streams[0],
    status        => 200,
    body          => sub { return () },
    callback_data => Test::Teardown::Guard->new(
        session    => $server,
        on_destroy => sub {
            my ($session) = @_;
            $destroyed++;
            if (!defined $session) {
                push @reentry_results, 'the weak reference was cleared before DESTROY';
                return;
            }
            my $ok = eval { $session->submit_ping(0, undef); 1 };
            push @reentry_results, $ok ? 'submit_ping returned without error' : $@;
            return;
        },
    ),
);
pump_sessions($client, $server);

is($destroyed, 0, 'the deferred provider is still held while the session lives');

# The only strong reference to the session; the guard holds a weak one.
undef $server;

is($destroyed, 1, 'session teardown released the provider exactly once');
is(scalar @reentry_results, 1, 'the destructor called back into the session once');
like(
    $reentry_results[0],
    qr/\QNet::HTTP2::nghttp2::Session: session has been destroyed\E/,
    'the re-entrant call was refused instead of dereferencing a deleted session'
);
is_deeply(\@warnings, [], 'teardown produced no warnings');
ok(1, 'the process survived a destructor that re-entered the dying session');

done_testing;
