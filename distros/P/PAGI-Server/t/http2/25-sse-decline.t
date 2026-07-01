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
    require PAGI::Server::Protocol::HTTP2;
    PAGI::Server::Protocol::HTTP2->available
        or plan(skip_all => 'HTTP/2 not available (Net::HTTP2::nghttp2 0.008+ required)');
}

# ============================================================
# Test: Declining an SSE request over HTTP/2 (sse.http.response.*)
# ============================================================
# Before sse.start, an application may DECLINE the stream and return a
# normal HTTP response (404/401/204/...) via sse.http.response.start /
# sse.http.response.body. First-send-wins: a stream event after a decline,
# and a decline after sse.start, MUST raise.

use PAGI::Server::Connection;
use PAGI::Server;
use PAGI::Server::Protocol::HTTP1;
use PAGI::Server::Protocol::HTTP2;

my $loop     = IO::Async::Loop->new;
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

sub create_h2_connection {
    my (%overrides) = @_;
    socketpair(my $sock_a, my $sock_b, AF_UNIX, SOCK_STREAM, 0)
        or die "socketpair: $!";
    $sock_a->blocking(0);
    $sock_b->blocking(0);
    my $app    = $overrides{app}    // sub { };
    my $server = $overrides{server} // create_test_server(app => $app);
    my $stream = IO::Async::Stream->new(
        read_handle  => $sock_a,
        write_handle => $sock_a,
        on_read      => sub { 0 },
    );
    my $conn = PAGI::Server::Connection->new(
        stream        => $stream,
        app           => $app,
        protocol      => $protocol,
        server        => $server,
        h2_protocol   => $server->{http2_protocol},
        alpn_protocol => 'h2',
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
            on_header          => $overrides{on_header}          // sub { 0 },
            on_frame_recv      => sub { 0 },
            on_data_chunk_recv => $overrides{on_data_chunk_recv} // sub { 0 },
            on_stream_close    => sub { 0 },
        },
    );
}

sub complete_h2_handshake {
    my ($client, $client_sock) = @_;
    $loop->loop_once(0.1);
    my $server_settings = '';
    $client_sock->sysread($server_settings, 4096);
    $client->send_connection_preface;
    my $data = $client->mem_send;
    $client_sock->syswrite($data);
    $loop->loop_once(0.1);
    $client->mem_recv($server_settings);
    $loop->loop_once(0.1);
    my $ack = '';
    $client_sock->sysread($ack, 4096);
    $client->mem_recv($ack) if length($ack);
    my $client_ack = $client->mem_send;
    $client_sock->syswrite($client_ack) if length($client_ack);
    $loop->loop_once(0.1);
    my $extra = '';
    $client_sock->sysread($extra, 4096);
    $client->mem_recv($extra) if length($extra);
}

sub exchange_frames {
    my ($client, $client_sock, $rounds) = @_;
    $rounds //= 10;
    for (1 .. $rounds) {
        $loop->loop_once(0.1);
        my $buf = '';
        $client_sock->sysread($buf, 16384);
        $client->mem_recv($buf) if length($buf);
        my $out = $client->mem_send;
        $client_sock->syswrite($out) if length($out);
    }
}

sub decline_request {
    my (%args) = @_;
    my ($conn, $stream_io, $client_sock, $server) =
        create_h2_connection(app => $args{app});

    my %headers;
    my $body = '';
    my $client = create_client(
        on_header          => sub { my ($sid, $n, $v) = @_; $headers{$n} = $v; return 0 },
        on_data_chunk_recv => sub { my ($sid, $d)    = @_; $body .= $d;         return 0 },
    );
    complete_h2_handshake($client, $client_sock);
    $client->submit_request(
        method    => 'GET',
        path      => $args{path} // '/events',
        scheme    => 'http',
        authority => 'localhost',
        headers   => [['accept', 'text/event-stream']],
    );
    $client_sock->syswrite($client->mem_send);
    exchange_frames($client, $client_sock, 20);

    $stream_io->close_now;
    $loop->remove($server);
    return (\%headers, $body);
}

subtest 'sse.http.response.* returns a plain HTTP 404 (declines the stream)' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'sse.http.response.start', status => 404,
                        headers => [['content-type', 'text/plain']] });
        await $send->({ type => 'sse.http.response.body', body => 'No such stream', more => 0 });
        return;
    };
    my ($headers, $body) = decline_request(app => $app);
    is($headers->{':status'}, '404', '404 status, not 200');
    is($headers->{'content-type'}, 'text/plain', 'plain content-type, NOT event-stream');
    like($body, qr/No such stream/, 'decline body delivered');
};

subtest 'multi-chunk decline body buffers until more=>0' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'sse.http.response.start', status => 401,
                        headers => [['x-deny', 'auth']] });
        await $send->({ type => 'sse.http.response.body', body => 'go ',   more => 1 });
        await $send->({ type => 'sse.http.response.body', body => 'away', more => 0 });
        return;
    };
    my ($headers, $body) = decline_request(app => $app);
    is($headers->{':status'}, '401', '401 status');
    is($headers->{'x-deny'},  'auth', 'custom header present');
    is($body, 'go away', 'body chunks concatenated before submission');
};

subtest 'first-send-wins: stream after decline, and decline after stream, raise' => sub {
    my ($after_decline_raised, $after_start_raised) = (0, 0);

    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'sse.http.response.start', status => 404, headers => [] });
        eval { await $send->({ type => 'sse.send', data => 'x' }); 1 } or $after_decline_raised = 1;
        await $send->({ type => 'sse.http.response.body', body => '', more => 0 });
        return;
    };
    decline_request(app => $app1);
    ok($after_decline_raised, 'sse.send after sse.http.response.start raised');

    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'sse.start', status => 200 });
        eval { await $send->({ type => 'sse.http.response.start', status => 404, headers => [] }); 1 }
            or $after_start_raised = 1;
        return;
    };
    decline_request(app => $app2);
    ok($after_start_raised, 'sse.http.response.start after sse.start raised');
};

done_testing;
