#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::SSE;

subtest 'on_close registers callback' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, sub { Future->done });

    my $called = 0;
    $sse->on_close(sub { $called = 1 });

    ok(!$called, 'callback not called yet');
};

subtest 'run waits for disconnect and calls on_close' => sub {
    my @events = (
        { type => 'sse.disconnect' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, $send);
    $sse->start->get;

    my $cleanup_ran = 0;
    $sse->on_close(sub { $cleanup_ran = 1 });

    $sse->run->get;

    ok($cleanup_ran, 'on_close callback ran');
    ok($sse->is_closed, 'connection is closed');
};

subtest 'multiple on_close callbacks run in order' => sub {
    my @events = ({ type => 'sse.disconnect' });
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };

    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, sub { Future->done });
    $sse->start->get;

    my @order;
    $sse->on_close(sub { push @order, 1 });
    $sse->on_close(sub { push @order, 2 });
    $sse->on_close(sub { push @order, 3 });

    $sse->run->get;

    is(\@order, [1, 2, 3], 'callbacks run in registration order');
};

subtest 'on_close works with async callbacks' => sub {
    my @events = ({ type => 'sse.disconnect' });
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };

    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, sub { Future->done });
    $sse->start->get;

    my $async_ran = 0;
    $sse->on_close(async sub { $async_ran = 1 });

    $sse->run->get;

    ok($async_ran, 'async callback ran');
};

subtest 'close method sets closed state' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, sub { Future->done });
    $sse->start->get;

    my $cleanup_ran = 0;
    $sse->on_close(sub { $cleanup_ran = 1 });

    $sse->close;

    ok($sse->is_closed, 'is_closed is true');
    ok($cleanup_ran, 'on_close ran on explicit close');
};

done_testing;
