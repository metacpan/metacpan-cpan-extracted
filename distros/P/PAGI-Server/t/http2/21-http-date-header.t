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
# Test: HTTP/2 responses carry a server-supplied Date header (h1/h2 parity)
# ============================================================
# HTTP/1.1 injects a Date response header; HTTP/2 must do the same so an
# application cannot tell the transports apart (SYNC C1).

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
            on_header          => $overrides{on_header}       // sub { 0 },
            on_frame_recv      => sub { 0 },
            on_data_chunk_recv => sub { 0 },
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

subtest 'HTTP/2 response includes a server-supplied Date header' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();
        await $send->({
            type => 'http.response.start', status => 200,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2c_connection(app => $app);

    my %headers;
    my $stream_closed = 0;
    my $client = create_client(
        on_header       => sub { my ($sid, $n, $v) = @_; $headers{lc $n} = $v; return 0 },
        on_stream_close => sub { $stream_closed = 1; return 0 },
    );

    $client->send_connection_preface;
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock);

    $client->submit_request(
        method => 'GET', path => '/', scheme => 'http', authority => 'localhost',
    );
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock, sub { $stream_closed });

    ok($stream_closed, 'request completed');
    ok(defined $headers{date}, 'HTTP/2 response carries a Date header');
    like($headers{date} // '', qr/GMT\z/, 'Date is in HTTP-date (GMT) format')
        if defined $headers{date};

    $stream_io->close_now;
    $loop->remove($server);
};

subtest 'HTTP/2 SSE response also includes a Date header (same as HTTP/1.1)' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $receive->();
        await $send->({ type => 'sse.start', status => 200 });
        await $send->({ type => 'sse.send', data => 'hello' });
    };

    my ($conn, $stream_io, $client_sock, $server) = create_h2c_connection(app => $app);

    my %headers;
    my $client = create_client(
        on_header => sub { my ($sid, $n, $v) = @_; $headers{lc $n} = $v; return 0 },
    );

    $client->send_connection_preface;
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock);

    $client->submit_request(
        method => 'GET', path => '/events', scheme => 'http', authority => 'localhost',
        headers => [['accept', 'text/event-stream']],
    );
    $client_sock->syswrite($client->mem_send);
    pump($client, $client_sock, sub { defined $headers{date} });

    ok(defined $headers{date}, 'HTTP/2 SSE response carries a Date header');

    $stream_io->close_now;
    $loop->remove($server);
};

done_testing;
