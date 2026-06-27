#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::SSE;

my @sent;
my $send = sub { push @sent, $_[0]; Future->done };
my $receive = sub { Future->new };  # Never resolves

subtest 'keepalive method exists' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, $send);
    ok($sse->can('keepalive'), 'keepalive method exists');
};

subtest 'keepalive sends sse.keepalive event' => sub {
    @sent = ();
    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, $send);

    $sse->keepalive(30)->get;

    is(scalar @sent, 1, 'one message sent');
    is($sent[0]{type}, 'sse.keepalive', 'correct event type');
    is($sent[0]{interval}, 30, 'correct interval');
    ok(!exists $sent[0]{comment} || $sent[0]{comment} eq '', 'no comment or empty comment when not specified');
};

subtest 'keepalive with comment sends both interval and comment' => sub {
    @sent = ();
    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, $send);

    $sse->keepalive(30, 'ping')->get;

    is(scalar @sent, 1, 'one message sent');
    is($sent[0]{type}, 'sse.keepalive', 'correct event type');
    is($sent[0]{interval}, 30, 'correct interval');
    is($sent[0]{comment}, 'ping', 'correct comment');
};

subtest 'keepalive returns self for chaining' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, $send);
    my $result = $sse->keepalive(25)->get;
    is(ref($result), ref($sse), 'returns same type');
    ok($result == $sse, 'returns $self for chaining');
};

subtest 'keepalive with 0 interval disables keepalive' => sub {
    @sent = ();
    my $sse = PAGI::SSE->new({ type => 'sse' }, $receive, $send);

    $sse->keepalive(0)->get;

    is(scalar @sent, 1, 'message sent');
    is($sent[0]{type}, 'sse.keepalive', 'correct event type');
    is($sent[0]{interval}, 0, 'interval is 0 to disable');
};

done_testing;
