#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::SSE;

subtest 'start sends sse.start event' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };

    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);

    $sse->start->get;

    is(scalar @sent, 1, 'one event sent');
    is($sent[0]{type}, 'sse.start', 'event type is sse.start');
    is($sent[0]{status}, 200, 'default status is 200');
    ok($sse->is_started, 'is_started is true after start');
};

subtest 'start with custom status and headers' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };

    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);

    $sse->start(
        status  => 201,
        headers => [['x-custom', 'value']],
    )->get;

    is($sent[0]{status}, 201, 'custom status');
    is($sent[0]{headers}, [['x-custom', 'value']], 'custom headers');
};

subtest 'start is idempotent' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };

    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);

    $sse->start->get;
    $sse->start->get;
    $sse->start->get;

    is(scalar @sent, 1, 'start only sends once');
};

done_testing;
