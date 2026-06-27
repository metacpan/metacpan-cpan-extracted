use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';
BEGIN {
    eval { require Net::Async::WebSocket::Client; 1 }
        or plan skip_all => 'Net::Async::WebSocket::Client required';
}

# End-to-end test of the pagi.transport backpressure callbacks. A single send
# larger than the high-water mark fires on_high_water at the synchronous
# post-write check (before the loop flushes); once it flushes to the reading
# client and the buffer falls below the low mark, on_drain fires.

my $loop = IO::Async::Loop->new;

my ($hit_high, $hit_drain) = (0, 0);

my $app = async sub {
    my ($scope, $receive, $send) = @_;

    if ($scope->{type} eq 'lifespan') {
        while (1) {
            my $e = await $receive->();
            if    ($e->{type} eq 'lifespan.startup')  { await $send->({ type => 'lifespan.startup.complete' }); }
            elsif ($e->{type} eq 'lifespan.shutdown') { await $send->({ type => 'lifespan.shutdown.complete' }); last; }
        }
        return;
    }

    return unless $scope->{type} eq 'websocket';

    await $send->({ type => 'websocket.accept' });

    my $t = $scope->{'pagi.transport'};
    $t->on_high_water(sub { $hit_high++ });
    $t->on_drain(sub     { $hit_drain++ });

    # 50 KB: over the 1 KB high-water mark configured below, but under the
    # ~64 KB WebSocket frame-size limit.
    await $send->({ type => 'websocket.send', bytes => ('x' x (50 * 1024)) });

    while (1) {
        my $e = await $receive->();
        last if $e->{type} eq 'websocket.disconnect';
    }
};

my $server = PAGI::Server->new(
    app => $app, host => '127.0.0.1', port => 0, quiet => 1,
    write_high_watermark => 1024,
    write_low_watermark  => 256,
);
$loop->add($server);
$server->listen->get;
my $port = $server->port;

# A client that reads incoming frames (so the server's write buffer drains).
my $client = Net::Async::WebSocket::Client->new(on_frame => sub { });
$loop->add($client);
$client->connect(url => "ws://127.0.0.1:$port/")->get;

my $deadline = time + 3;
$loop->loop_once(0.02) while (!$hit_high || !$hit_drain) && time < $deadline;

ok($hit_high,  'on_high_water fired when a send exceeded the high-water mark');
ok($hit_drain, 'on_drain fired once the buffer drained below the low-water mark');

eval { $client->close };
eval { $loop->remove($client) };
$server->shutdown->get;
$loop->remove($server);

done_testing;
