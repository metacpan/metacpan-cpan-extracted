use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../../lib";

# Cross-repo smoke test: PAGI-Tools' PAGI::App::Router must drive the real
# PAGI::Server to return a normal HTTP 404 for an unmatched SSE route, instead
# of crashing the connection. Each repo is unit-tested in isolation; this proves
# the whole chain (router emits sse.http.response.* -> server returns a real
# HTTP response -> client reads a 404, not an event stream).
#
# Skips unless PAGI::Server is on @INC, so PAGI-Tools' standalone suite stays
# independent. Run it with:
#   prove -I <PAGI-Server>/lib -lr t/integration/sse-decline-end-to-end.t

eval { require Future::IO::Impl::IOAsync; 1 }
    or plan skip_all => 'Future::IO::Impl::IOAsync required for SSE tests';
eval { require PAGI::Server; 1 }
    or plan skip_all => 'PAGI::Server not on @INC; run with -I <PAGI-Server>/lib';

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

use PAGI::App::Router;
use IO::Socket::INET;

my $loop = IO::Async::Loop->new;

sub create_server {
    my ($app) = @_;
    my $server = PAGI::Server->new(
        app => $app, host => '127.0.0.1', port => 0, quiet => 1, shutdown_timeout => 1,
    );
    $loop->add($server);
    $server->listen->get;
    return $server;
}

sub sse_get {
    my ($port, $path) = @_;
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 5,
    ) or return ('', 0);
    print $sock "GET $path HTTP/1.1\r\nHost: 127.0.0.1:$port\r\nAccept: text/event-stream\r\n\r\n";
    $sock->blocking(0);
    my $wire = '';
    my $eof  = 0;
    my $deadline = time + 5;
    while (time < $deadline) {
        my $buf;
        my $n = sysread($sock, $buf, 4096);
        if (defined $n && $n > 0) { $wire .= $buf }
        elsif (defined $n && $n == 0) { $eof = 1; last }
        $loop->loop_once(0.05);
    }
    close $sock;
    $loop->loop_once(0.05) for 1 .. 20;
    return ($wire, $eof);
}

subtest 'unmatched SSE route returns a real HTTP 404 over the real server' => sub {
    my $router = PAGI::App::Router->new;
    # An SSE route exists, but the request targets a different path.
    $router->sse('/events' => async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'sse.start', status => 200 });
    });

    my $server = create_server($router->to_app);
    my ($wire, $eof) = sse_get($server->port, '/nope');

    like($wire, qr{HTTP/1\.1 404},        'unmatched SSE route -> 404, not a crash');
    like($wire, qr/Not Found/,             'decline body delivered');
    unlike($wire, qr{text/event-stream},   'NOT an event stream');
    ok($eof, 'connection closed');

    $server->shutdown->get;
};

done_testing;
