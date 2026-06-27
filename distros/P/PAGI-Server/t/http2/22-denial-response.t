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
# Test: WebSocket Denial Response over HTTP/2 (SYNC E1)
# ============================================================
# Verifies that the server handles websocket.http.response.start/.body
# events, returning a custom HTTP response (not 200/403) when the app
# rejects the WebSocket handshake before accepting it.

use PAGI::Server::Connection;
use PAGI::Server;
use PAGI::Server::Protocol::HTTP1;
use PAGI::Server::Protocol::HTTP2;

my $loop     = IO::Async::Loop->new;
my $protocol = PAGI::Server::Protocol::HTTP1->new;

# ============================================================
# Helpers — copied from t/http2/07-websocket.t
# ============================================================

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

# ============================================================
# Extension is advertised on h2 WebSocket scope; custom denial response
# ============================================================
subtest 'h2 WebSocket scope advertises denial-response extension' => sub {
    my $captured_scope;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope if $scope->{type} eq 'websocket';
        await $receive->();  # websocket.connect
        await $send->({
            type    => 'websocket.http.response.start',
            status  => 401,
            headers => [['x-deny', 'auth']],
        });
        await $send->({
            type => 'websocket.http.response.body',
            body => 'nope',
        });
        return;
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2_connection(app => $app);

    my %headers;
    my $body = '';

    my $client = create_client(
        on_header          => sub { my ($sid, $n, $v) = @_; $headers{$n} = $v; return 0 },
        on_data_chunk_recv => sub { my ($sid, $d)    = @_; $body .= $d;         return 0 },
    );

    complete_h2_handshake($client, $client_sock);

    # Extended CONNECT (RFC 8441) — matches t/http2/07-websocket.t submit_request
    $client->submit_request(
        method    => 'CONNECT',
        path      => '/ws/test',
        scheme    => 'https',
        authority => 'localhost',
        headers   => [
            [':protocol', 'websocket'],
            ['sec-websocket-version', '13'],
        ],
        body => sub { return undef },  # streaming: keep open
    );
    $client_sock->syswrite($client->mem_send);
    exchange_frames($client, $client_sock, 20);

    ok(defined $captured_scope, 'app was called with a websocket scope');
    ok(
        $captured_scope && $captured_scope->{extensions}{'websocket.http.response'},
        'extension websocket.http.response is advertised on h2 ws scope',
    );
    is($headers{':status'}, '401', 'h2 denial uses custom 401, not 200 or 403');
    is($headers{'x-deny'},  'auth', 'custom denial header is present');
    like($body, qr/nope/, 'custom body is present');

    $stream_io->close_now;
    $loop->remove($server);
};

# ============================================================
# Denial with multi-chunk body (more => 1 then more => 0)
# ============================================================
subtest 'h2 denial buffers multiple body chunks until more=>0' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();
        await $send->({
            type    => 'websocket.http.response.start',
            status  => 429,
            headers => [['retry-after', '60']],
        });
        await $send->({ type => 'websocket.http.response.body', body => 'try ', more => 1 });
        await $send->({ type => 'websocket.http.response.body', body => 'later', more => 0 });
        return;
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2_connection(app => $app);

    my %headers;
    my $body = '';

    my $client = create_client(
        on_header          => sub { my ($sid, $n, $v) = @_; $headers{$n} = $v; return 0 },
        on_data_chunk_recv => sub { my ($sid, $d)    = @_; $body .= $d;         return 0 },
    );

    complete_h2_handshake($client, $client_sock);

    $client->submit_request(
        method    => 'CONNECT',
        path      => '/ws/rate-limited',
        scheme    => 'https',
        authority => 'localhost',
        headers   => [
            [':protocol', 'websocket'],
            ['sec-websocket-version', '13'],
        ],
        body => sub { return undef },
    );
    $client_sock->syswrite($client->mem_send);
    exchange_frames($client, $client_sock, 20);

    is($headers{':status'},     '429', '429 status used');
    is($headers{'retry-after'}, '60',  'custom retry-after header present');
    is($body, 'try later', 'body chunks were concatenated before submission');

    $stream_io->close_now;
    $loop->remove($server);
};

# ============================================================
# websocket.close-before-accept bare 403 path is unaffected
# ============================================================
subtest 'bare-403 fallback (websocket.close before accept) still works' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();  # websocket.connect
        await $send->({ type => 'websocket.close' });
        return;
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2_connection(app => $app);

    my %headers;

    my $client = create_client(
        on_header => sub { my ($sid, $n, $v) = @_; $headers{$n} = $v; return 0 },
    );

    complete_h2_handshake($client, $client_sock);

    $client->submit_request(
        method    => 'CONNECT',
        path      => '/ws/reject',
        scheme    => 'https',
        authority => 'localhost',
        headers   => [
            [':protocol', 'websocket'],
            ['sec-websocket-version', '13'],
        ],
        body => sub { return undef },
    );
    $client_sock->syswrite($client->mem_send);
    exchange_frames($client, $client_sock, 20);

    is($headers{':status'}, '403', 'bare websocket.close still gives 403');

    $stream_io->close_now;
    $loop->remove($server);
};

done_testing;
