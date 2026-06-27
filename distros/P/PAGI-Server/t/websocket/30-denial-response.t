use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use IO::Socket::INET;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

my $loop = IO::Async::Loop->new;

# Helper to create a PAGI server with the given app
sub create_server {
    my ($test_app) = @_;

    my $server = PAGI::Server->new(
        app   => $test_app,
        host  => '127.0.0.1',
        port  => 0,
        quiet => 1,
    );

    $loop->add($server);
    $server->listen->get;

    return $server;
}

# Helper to send a raw WebSocket upgrade request and read the HTTP response.
# Returns the raw response string (everything up to and including the body).
sub raw_ws_upgrade_and_read {
    my ($port) = @_;

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
    );
    return undef unless $sock;

    my $key = 'dGhlIHNhbXBsZSBub25jZQ==';
    print $sock "GET / HTTP/1.1\r\n";
    print $sock "Host: 127.0.0.1:$port\r\n";
    print $sock "Upgrade: websocket\r\n";
    print $sock "Connection: Upgrade\r\n";
    print $sock "Sec-WebSocket-Key: $key\r\n";
    print $sock "Sec-WebSocket-Version: 13\r\n";
    print $sock "\r\n";

    # Read the response: headers + body (up to connection close or timeout)
    $sock->blocking(0);
    my $response = '';
    my $deadline = time + 5;
    my $headers_done = 0;
    my $content_length;
    while (time < $deadline) {
        my $buf;
        my $n = sysread($sock, $buf, 4096);
        if (defined $n && $n > 0) {
            $response .= $buf;
            # Once we have the header block, extract content-length
            if (!$headers_done && $response =~ /\r\n\r\n/) {
                $headers_done = 1;
                if ($response =~ /content-length:\s*(\d+)/i) {
                    $content_length = $1;
                }
            }
            # If we know the content-length, stop when we have it all
            if ($headers_done && defined $content_length) {
                my ($header_part) = $response =~ /^(.*?\r\n\r\n)/s;
                my $body_so_far = length($response) - length($header_part);
                last if $body_so_far >= $content_length;
            }
        }
        elsif (defined $n && $n == 0) {
            last;  # Connection closed by server
        }
        $loop->loop_once(0.1);
    }

    close $sock;
    return $response;
}

# ---------------------------------------------------------------------------
# Test: custom HTTP 401 denial response (websocket.http.response extension)
# ---------------------------------------------------------------------------

subtest 'websocket.http.response.start/.body sends custom 401' => sub {
    my $captured_scope;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;

        # Handle lifespan scope
        if ($scope->{type} eq 'lifespan') {
            while (1) {
                my $event = await $receive->();
                if ($event->{type} eq 'lifespan.startup') {
                    await $send->({ type => 'lifespan.startup.complete' });
                }
                elsif ($event->{type} eq 'lifespan.shutdown') {
                    await $send->({ type => 'lifespan.shutdown.complete' });
                    last;
                }
            }
            return;
        }

        die "expected websocket scope" unless $scope->{type} eq 'websocket';
        $captured_scope = $scope;

        my $connect = await $receive->();    # websocket.connect

        await $send->({
            type    => 'websocket.http.response.start',
            status  => 401,
            headers => [
                ['content-type', 'application/json'],
                ['x-deny',       'auth'],
            ],
        });
        await $send->({
            type => 'websocket.http.response.body',
            body => '{"error":"unauthorized"}',
        });
        return;
    };

    my $server = create_server($app);
    my $port   = $server->port;

    my $raw_response = raw_ws_upgrade_and_read($port);

    SKIP: {
        skip "Cannot connect to server", 4 unless defined $raw_response && length $raw_response;

        # The server must have been called and the scope captured by now
        my $deadline = time + 3;
        while (!$captured_scope && time < $deadline) {
            $loop->loop_once(0.1);
        }

        ok(
            $captured_scope && $captured_scope->{extensions}{'websocket.http.response'},
            'extension websocket.http.response advertised on ws scope',
        );

        like(
            $raw_response,
            qr{^HTTP/1\.1 401\b},
            'custom 401 status (not 101, not bare 403)',
        );

        like(
            $raw_response,
            qr{x-deny:\s*auth}i,
            'custom x-deny header present',
        );

        like(
            $raw_response,
            qr{\{"error":"unauthorized"\}},
            'custom JSON body present',
        );
    }

    $server->shutdown->get;
};

done_testing;
