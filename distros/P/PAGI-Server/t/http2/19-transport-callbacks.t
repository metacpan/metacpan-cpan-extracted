use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use IO::Async::Stream;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Socket qw(AF_UNIX SOCK_STREAM);

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';
BEGIN {
    eval { require Net::HTTP2::nghttp2; Net::HTTP2::nghttp2->VERSION(0.007); 1 }
        or plan(skip_all => 'Net::HTTP2::nghttp2 0.007+ not installed (optional)');
}

# ============================================================
# Test: pagi.transport on_high_water / on_drain fire on a real HTTP/2 stream
# ============================================================
# A single streaming chunk larger than the high-water mark fires on_high_water
# at the synchronous post-push poke (before nghttp2 pulls from the per-stream
# queue). nghttp2 then pulls the queue down past the low-water mark (the client
# uses the default 64KB window and consumes), firing on_drain (deferred via
# loop->later). Both must be observed by the time the stream closes.

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
            on_data_chunk_recv => sub { 0 },   # consume data -> window reopens
            on_stream_close    => $overrides{on_stream_close} // sub { 0 },
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

subtest 'on_high_water and on_drain fire on an h2 streaming response' => sub {
    my ($hit_high, $hit_drain) = (0, 0);

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();

        my $t = $scope->{'pagi.transport'};
        $t->on_high_water(sub { $hit_high++ });
        $t->on_drain(sub     { $hit_drain++ });

        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        # 70 KB in one chunk: over the 64 KB default high-water mark. The
        # post-push poke fires on_high_water before nghttp2 pulls; nghttp2 then
        # drains the queue below the 16 KB low mark, firing on_drain (deferred).
        await $send->({ type => 'http.response.body', body => ('x' x (70 * 1024)), more => 1 });
        await $send->({ type => 'http.response.body', body => 'end', more => 0 });
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2c_connection(app => $app);

    my $stream_closed = 0;
    my $client = create_client(on_stream_close => sub { $stream_closed = 1; return 0 });

    $client->send_connection_preface;
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock);

    $client->submit_request(
        method => 'GET', path => '/streaming', scheme => 'http', authority => 'localhost',
    );
    $client_sock->syswrite($client->mem_send);

    # Pump until the stream closes (and at least until both callbacks fire).
    pump($client, $client_sock, sub { $stream_closed && $hit_high && $hit_drain });

    ok($stream_closed, 'stream completed and closed');
    ok($hit_high,  'on_high_water fired when the queue exceeded the high mark');
    ok($hit_drain, 'on_drain fired once nghttp2 drained the queue below the low mark');

    $stream_io->close_now;
    $loop->remove($server);
};

done_testing;
