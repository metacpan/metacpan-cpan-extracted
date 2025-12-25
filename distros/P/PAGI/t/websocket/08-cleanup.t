#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::WebSocket;

subtest 'on_close callback runs on disconnect' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.disconnect', code => 1000, reason => 'Bye' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my ($called_code, $called_reason);
    $ws->on_close(async sub {
        my ($code, $reason) = @_;
        $called_code = $code;
        $called_reason = $reason;
    });

    # Trigger disconnect
    $ws->receive->get;

    is($called_code, 1000, 'on_close received code');
    is($called_reason, 'Bye', 'on_close received reason');
};

subtest 'on_close runs after each_* loops' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => 'msg' },
        { type => 'websocket.disconnect', code => 1001 },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my $cleanup_ran = 0;
    $ws->on_close(async sub { $cleanup_ran = 1 });

    $ws->each_text(async sub {})->get;

    ok($cleanup_ran, 'on_close ran after each_text');
};

subtest 'multiple on_close callbacks run in order' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.disconnect', code => 1000 },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my @order;
    $ws->on_close(async sub { push @order, 1 });
    $ws->on_close(async sub { push @order, 2 });
    $ws->on_close(async sub { push @order, 3 });

    $ws->receive->get;

    is(\@order, [1, 2, 3], 'callbacks run in registration order');
};

subtest 'on_close runs on explicit close()' => sub {
    my @events = (
        { type => 'websocket.connect' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my $cleanup_ran = 0;
    $ws->on_close(async sub { $cleanup_ran = 1 });

    $ws->close(1000, 'Goodbye')->get;

    ok($cleanup_ran, 'on_close ran on explicit close');
};

subtest 'on_close only runs once' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.disconnect', code => 1000 },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my $call_count = 0;
    $ws->on_close(async sub { $call_count++ });

    $ws->receive->get;    # triggers disconnect
    $ws->receive->get;    # already closed
    $ws->close->get;      # already closed

    is($call_count, 1, 'on_close only called once');
};

subtest 'on_close exception does not prevent other callbacks' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.disconnect', code => 1000 },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my $second_ran = 0;
    $ws->on_close(async sub { die "First callback error" });
    $ws->on_close(async sub { $second_ran = 1 });

    # Should not die, should run second callback
    $ws->receive->get;

    ok($second_ran, 'second callback ran despite first dying');
};

subtest 'on_close works with sync callbacks' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.disconnect', code => 1000, reason => 'Normal' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my ($sync_code, $sync_reason);
    my $async_ran = 0;

    # Mix of sync and async callbacks
    $ws->on_close(sub {
        my ($code, $reason) = @_;
        $sync_code = $code;
        $sync_reason = $reason;
    });
    $ws->on_close(async sub { $async_ran = 1 });

    $ws->receive->get;

    is($sync_code, 1000, 'sync callback received code');
    is($sync_reason, 'Normal', 'sync callback received reason');
    ok($async_ran, 'async callback also ran');
};

done_testing;
