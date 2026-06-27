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
# Test: pagi.transport on a real SSE-over-HTTP/2 stream
# ============================================================
# SSE-over-h2 must provide the same pagi.transport handle as HTTP/2 streaming
# and HTTP/1.1: the app cannot tell which transport carries its events.
# Subtest 1 exercises on_high_water / on_drain on a real stream; subtest 2
# proves the handle (and its $ss reference cycle) is collected at teardown.

use PAGI::Server::Connection;
use PAGI::Server;
use PAGI::Server::Protocol::HTTP1;
use PAGI::Server::Protocol::HTTP2;

my $loop = IO::Async::Loop->new;
my $protocol = PAGI::Server::Protocol::HTTP1->new;

sub create_test_server {
    my (%args) = @_;
    my $server = PAGI::Server->new(
        app => $args{app} // sub { }, host => '127.0.0.1', port => 0,
        quiet => 1, http2 => 1, %args,
    );
    $loop->add($server);
    return $server;
}

sub create_h2c_connection {
    my (%overrides) = @_;
    socketpair(my $sock_a, my $sock_b, AF_UNIX, SOCK_STREAM, 0) or die "socketpair: $!";
    $sock_a->blocking(0);
    $sock_b->blocking(0);
    my $app = $overrides{app} // sub { };
    my $server = $overrides{server} // create_test_server(app => $app);
    my $stream = IO::Async::Stream->new(
        read_handle => $sock_a, write_handle => $sock_a, on_read => sub { 0 },
    );
    my $conn = PAGI::Server::Connection->new(
        stream => $stream, app => $app, protocol => $protocol, server => $server,
        h2_protocol => $server->{http2_protocol}, h2c_enabled => $server->{h2c_enabled},
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
            on_begin_headers   => sub { 0 },
            on_header          => sub { 0 },
            on_frame_recv      => sub { 0 },
            on_data_chunk_recv => $overrides{on_data_chunk_recv} // sub { 0 },
            on_stream_close    => $overrides{on_stream_close}    // sub { 0 },
        },
    );
}

sub pump {
    my ($client, $client_sock, $cond) = @_;
    for (1 .. 200) {
        $loop->loop_once(0.02);
        my $buf = '';
        $client_sock->sysread($buf, 65536);
        $client->mem_recv($buf) if length($buf);
        my $out = $client->mem_send;
        $client_sock->syswrite($out) if length($out);
        last if $cond && $cond->();
    }
}

sub do_handshake {
    my ($client, $client_sock) = @_;
    $client->send_connection_preface;
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock);
}

sub submit_sse_request {
    my ($client, $client_sock) = @_;
    $client->submit_request(
        method => 'GET', path => '/events', scheme => 'http', authority => 'localhost',
        headers => [['accept', 'text/event-stream']],
    );
    $client_sock->syswrite($client->mem_send);
}

subtest 'on_high_water and on_drain fire on an SSE-over-h2 stream' => sub {
    my ($hit_high, $hit_drain) = (0, 0);

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();

        my $t = $scope->{'pagi.transport'};
        $t->on_high_water(sub { $hit_high++ });
        $t->on_drain(sub     { $hit_drain++ });

        await $send->({ type => 'sse.start', status => 200 });
        # One 70 KB event: over the 64 KB high-water mark. The post-push poke
        # fires on_high_water before nghttp2 pulls; nghttp2 then drains the
        # per-stream queue below the 16 KB low mark, firing on_drain (deferred).
        await $send->({ type => 'sse.send', data => ('x' x (70 * 1024)) });
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2c_connection(app => $app);
    my $client = create_client;

    do_handshake($client, $client_sock);
    submit_sse_request($client, $client_sock);
    pump($client, $client_sock, sub { $hit_high && $hit_drain });

    ok($hit_high,  'on_high_water fired when the per-stream queue exceeded the high mark');
    ok($hit_drain, 'on_drain fired once nghttp2 drained the queue below the low mark');

    $stream_io->close_now;
    $loop->remove($server);
};

subtest 'SSE-over-h2 transport handle (and its $ss cycle) is collected at teardown' => sub {
    # The app weak-probes its OWN transport handle (race-free: the app always
    # runs), sends a few events, then returns. With the app coroutine complete
    # the scope is released, so the handle is held only by $ss->{transport_state}.
    # A client RST_STREAM drives _h2_on_close, which must delete that ref and
    # break the cycle -- otherwise the stream state leaks for the life of the
    # process (one per SSE request).
    my ($saw_handle, $probe);

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();

        my $t = $scope->{'pagi.transport'};
        $saw_handle = $t ? 1 : 0;
        weaken($probe = $t);

        await $send->({ type => 'sse.start', status => 200 });
        for my $i (1 .. 3) {
            await $send->({ type => 'sse.send', data => "event$i" });
        }
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2c_connection(app => $app);
    my $client = create_client;

    do_handshake($client, $client_sock);
    submit_sse_request($client, $client_sock);
    pump($client, $client_sock, sub { $saw_handle });

    ok($saw_handle, 'transport handle was attached to the SSE-over-h2 scope');

    # Client closes the SSE stream (stream id 1) -> server _h2_on_close.
    $client->submit_rst_stream(1, 8);   # 8 = CANCEL
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock);

    # Drive deferred teardown (loop->later) until the probe is collected.
    for (1 .. 200) {
        last unless defined $probe;
        $loop->loop_once(0.01);
    }

    is($probe, undef, 'transport handle (and its $ss cycle) collected after teardown; no leak');

    $stream_io->close_now;
    $loop->remove($server);
};

done_testing;
