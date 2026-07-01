use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../../lib";

# Cross-repo smoke test: PAGI-Tools' PAGI::SSE->close(reason) must drive the real
# PAGI::Server to end the SSE stream on the wire. Each repo is unit-tested in
# isolation; this proves the whole chain (Tools close() -> sse.close event ->
# server END_STREAM/terminator -> client EOF).
#
# Skips unless PAGI-Tools is on @INC, so PAGI-Server's standalone suite stays
# independent. Run it with:
#   prove -I <PAGI-Tools>/lib -lr t/integration/sse-close-end-to-end.t

eval { require Future::IO::Impl::IOAsync; 1 }
    or plan skip_all => 'Future::IO::Impl::IOAsync required for SSE tests';
eval { require PAGI::SSE; 1 }
    or plan skip_all => 'PAGI::SSE (PAGI-Tools) not on @INC; run with -I <PAGI-Tools>/lib';

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

use PAGI::Server;   # PAGI::SSE is loaded by the require-guard above (skip-safe)
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
    my ($port) = @_;
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 5,
    ) or return ('', 0);
    print $sock "GET / HTTP/1.1\r\nHost: 127.0.0.1:$port\r\nAccept: text/event-stream\r\n\r\n";
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

subtest 'PAGI::SSE->close(reason) ends the stream over the real server' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        my $sse = PAGI::SSE->new($scope, $receive, $send);

        await $sse->start;
        await $sse->send_event(event => 'tick', data => '1');

        # Tools-level explicit close: sends sse.close, which the server acts on.
        await $sse->close(reason => 'smoke_done');
    };

    my $server = create_server($app);
    my ($wire, $eof) = sse_get($server->port);

    like($wire, qr/HTTP\/1\.1 200/,      '200 OK');
    like($wire, qr/event: tick\n/,        'event delivered');
    like($wire, qr/data: 1\n/,            'data delivered');
    ok($eof, 'server closed the stream after PAGI::SSE->close');

    $server->shutdown->get;
};

done_testing;
