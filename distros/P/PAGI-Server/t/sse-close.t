use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";

eval { require Future::IO::Impl::IOAsync; 1 }
    or plan skip_all => 'Future::IO::Impl::IOAsync required for SSE tests';

use PAGI::Server;
use IO::Socket::INET;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# Regression for the sse.close send-event (HTTP/1.1):
#   - sse.close is accepted (does not raise) and ends the stream;
#   - sending after sse.close raises (failed Future);
#   - the post-close event never reaches the wire;
#   - the server closes the connection.
# Both an explicit sse.close and a plain return must end the stream identically
# on the wire (D3: keep return-to-end valid).

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

# Open an SSE GET, read raw bytes until the server closes (EOF) or a deadline,
# then drain the loop so the app coroutine finishes. Returns (wire, saw_eof).
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
        elsif (defined $n && $n == 0) { $eof = 1; last }   # server closed the stream
        $loop->loop_once(0.05);
    }
    close $sock;
    $loop->loop_once(0.05) for 1 .. 20;   # let the app coroutine run to completion
    return ($wire, $eof);
}

subtest 'sse.close ends the stream; send-after-close raises' => sub {
    my ($close_ok, $post_close_raised) = (0, 0);

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        die "expected sse scope" unless ($scope->{type} // '') eq 'sse';

        await $send->({ type => 'sse.start', status => 200,
                        headers => [ ['content-type', 'text/event-stream'] ] });
        await $send->({ type => 'sse.send', event => 'tick', data => '1' });

        eval { await $send->({ type => 'sse.close', reason => 'done_testing' }); $close_ok = 1; 1 };

        # After sse.close, any further send MUST raise.
        eval { await $send->({ type => 'sse.send', event => 'late', data => 'LATE' }); 1 }
            or $post_close_raised = 1;
    };

    my $server = create_server($app);
    my ($wire, $eof) = sse_get($server->port);

    like($wire, qr/HTTP\/1\.1 200/,                 '200 OK');
    like($wire, qr/content-type:\s*text\/event-stream/i, 'event-stream content type');
    like($wire, qr/data: 1/,                        'tick event delivered before close');
    ok($close_ok,          'sse.close was accepted (did not raise)');
    ok($post_close_raised, 'sse.send after sse.close raised');
    unlike($wire, qr/LATE/, 'post-close event did not reach the wire');
    ok($eof,               'server closed the connection after sse.close');

    $server->shutdown->get;
};

subtest 'return-to-end still terminates the stream (D3)' => sub {
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'sse.start', status => 200,
                        headers => [ ['content-type', 'text/event-stream'] ] });
        await $send->({ type => 'sse.send', event => 'tick', data => 'R' });
        return;   # no sse.close -- end by returning
    };

    my $server = create_server($app);
    my ($wire, $eof) = sse_get($server->port);

    like($wire, qr/data: R/, 'event delivered');
    ok($eof,                 'server closed the connection on return');

    $server->shutdown->get;
};

done_testing;
