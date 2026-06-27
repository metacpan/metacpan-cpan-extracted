use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::WebSocket::Client;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# B5 (SYNC A2): a server-detected abnormal WebSocket close must deliver a
# populated reason (and the matching close code) in the websocket.disconnect
# event the app receives -- not the old hardcoded { code => 1006, reason => '' }.
#
# Queue overflow is the deterministic trigger: it runs the same
# _handle_disconnect -> disconnect-event path that every other server-detected
# close uses, so it validates the centralized reason/code plumbing.

my $loop = IO::Async::Loop->new;

subtest 'queue overflow delivers reason=queue_overflow, code=1008' => sub {
    my $disconnect_reason;
    my $disconnect_code;
    my $app_started = 0;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
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

        return unless $scope->{type} eq 'websocket';

        await $send->({ type => 'websocket.accept' });
        $app_started = 1;

        # Let the client flood the receive queue past the limit first.
        await $loop->delay_future(after => 0.3);

        # Drain until the server reports the disconnect.
        while (1) {
            my $event = await $receive->();
            if ($event->{type} eq 'websocket.disconnect') {
                $disconnect_reason = $event->{reason};
                $disconnect_code   = $event->{code};
                last;
            }
        }
    };

    my $server = PAGI::Server->new(
        app               => $app,
        host              => '127.0.0.1',
        port              => 0,
        quiet             => 1,
        max_receive_queue => 5,
    );
    $loop->add($server);
    $server->listen->get;
    my $port = $server->port;

    my $client = Net::Async::WebSocket::Client->new;
    $loop->add($client);

    eval {
        $client->connect(url => "ws://127.0.0.1:$port/")->get;

        my $deadline = time + 2;
        while (!$app_started && time < $deadline) {
            $loop->loop_once(0.01);
        }

        # Flood past max_receive_queue while the app is still delaying.
        for my $i (1 .. 20) {
            eval { $client->send_text_frame("msg$i") };
            last if $@;
            $loop->loop_once(0.01);
        }

        # Let the app drain and observe the disconnect.
        $deadline = time + 3;
        while (!defined($disconnect_reason) && time < $deadline) {
            $loop->loop_once(0.05);
        }
    };

    is($disconnect_reason, 'queue_overflow',
        'app receives standard reason token for queue overflow');
    is($disconnect_code, 1008,
        'app receives the 1008 close code, not the 1006 default');

    eval { $loop->remove($client) };
    $server->shutdown->get;
    eval { $loop->remove($server) };
};

done_testing;
