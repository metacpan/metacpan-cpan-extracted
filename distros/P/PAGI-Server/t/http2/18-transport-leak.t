use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use IO::Async::Stream;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Socket qw(AF_UNIX SOCK_STREAM);
use Scalar::Util qw(weaken);

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';
BEGIN {
    eval { require Net::HTTP2::nghttp2; Net::HTTP2::nghttp2->VERSION(0.007); 1 }
        or plan(skip_all => 'Net::HTTP2::nghttp2 0.007+ not installed (optional)');
}

# ============================================================
# Test: the HTTP/2 pagi.transport handle is collected after the request
# ============================================================
# The handle is stored on the stream state ($ss->{transport_state}) and its
# measure/arm_drain closures capture $ss strongly -- a reference cycle. Once the
# request completes and the connection drops its external h2_streams ref, the
# cycle would keep $ss + the handle + its closures alive for the life of the
# process (one per h2 request) unless teardown breaks it (delete
# $ss->{transport_state}). The handle and $ss are mutually retaining, so a weak
# probe to the handle detects the cycle leak.

use PAGI::Server::Connection;
use PAGI::Server;
use PAGI::Server::Protocol::HTTP1;
use PAGI::Server::Protocol::HTTP2;

my $loop = IO::Async::Loop->new;
my $protocol = PAGI::Server::Protocol::HTTP1->new;

sub create_test_server {
    my (%args) = @_;
    my $server = PAGI::Server->new(
        app   => $args{app} // sub { },
        host  => '127.0.0.1',
        port  => 0,
        quiet => 1,
        http2 => 1,
        %args,
    );
    $loop->add($server);
    return $server;
}

sub create_h2c_connection {
    my (%overrides) = @_;

    socketpair(my $sock_a, my $sock_b, AF_UNIX, SOCK_STREAM, 0)
        or die "socketpair: $!";
    $sock_a->blocking(0);
    $sock_b->blocking(0);

    my $app = $overrides{app} // sub { };
    my $server = $overrides{server} // create_test_server(app => $app);

    my $stream = IO::Async::Stream->new(
        read_handle  => $sock_a,
        write_handle => $sock_a,
        on_read => sub { 0 },
    );

    my $conn = PAGI::Server::Connection->new(
        stream      => $stream,
        app         => $app,
        protocol    => $protocol,
        server      => $server,
        h2_protocol => $server->{http2_protocol},
        h2c_enabled => $server->{h2c_enabled},
    );

    $server->add_child($stream);
    $conn->start;

    return ($conn, $stream, $sock_b, $server);
}

sub create_client {
    my (%overrides) = @_;
    require Net::HTTP2::nghttp2::Session;
    return Net::HTTP2::nghttp2::Session->new_client(
        callbacks => {
            on_begin_headers   => $overrides{on_begin_headers}   // sub { 0 },
            on_header          => $overrides{on_header}          // sub { 0 },
            on_frame_recv      => $overrides{on_frame_recv}      // sub { 0 },
            on_data_chunk_recv => $overrides{on_data_chunk_recv} // sub { 0 },
            on_stream_close    => $overrides{on_stream_close}    // sub { 0 },
        },
    );
}

sub pump {
    my ($client, $client_sock, $cond) = @_;
    for (1 .. 100) {
        $loop->loop_once(0.02);
        my $buf = '';
        $client_sock->sysread($buf, 65536);
        $client->mem_recv($buf) if length($buf);
        my $out = $client->mem_send;
        $client_sock->syswrite($out) if length($out);
        last if $cond && $cond->();
    }
}

subtest 'h2 transport handle (and its stream-state cycle) is collected after the request' => sub {
    # The app weak-probes its OWN transport handle. This is race-free: the app
    # is guaranteed to run, so the probe is always captured while the handle is
    # live (unlike polling $conn->{h2_streams} from outside, which misses a fast
    # request that is created and torn down within a single loop tick).
    my ($saw_handle, $probe);

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();

        my $t = $scope->{'pagi.transport'};
        $saw_handle = $t ? 1 : 0;
        weaken($probe = $t);   # weak: survives the request only if leaked

        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        # Stream a few chunks so the handle is genuinely exercised (send_queue
        # populated, the cycle fully formed).
        for my $i (1 .. 3) {
            await $send->({ type => 'http.response.body', body => "chunk$i", more => 1 });
        }
        await $send->({ type => 'http.response.body', body => 'final', more => 0 });
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2c_connection(app => $app);

    my $stream_closed = 0;
    my $client = create_client(on_stream_close => sub { $stream_closed = 1; return 0 });

    # h2c handshake.
    $client->send_connection_preface;
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock);

    $client->submit_request(
        method    => 'GET',
        path      => '/streaming',
        scheme    => 'http',
        authority => 'localhost',
    );
    $client_sock->syswrite($client->mem_send);

    # Pump until the stream completes and closes (request fully handled).
    pump($client, $client_sock, sub { $stream_closed });

    ok($stream_closed, 'stream completed and closed');
    ok($saw_handle,    'transport handle was attached to the h2 scope');

    # Drive deferred teardown (loop->later) AND adopted-future cleanup so the
    # scope/coroutine that transiently hold the handle are released. Break early
    # once the probe is collected.
    for (1 .. 200) {
        last unless defined $probe;
        $loop->loop_once(0.01);
    }

    is($probe, undef,
        'transport handle (and its $ss cycle) collected after teardown; no leak');

    $stream_io->close_now;
    $loop->remove($server);
};

done_testing;
