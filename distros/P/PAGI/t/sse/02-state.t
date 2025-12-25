#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future;

use lib 'lib';
use PAGI::SSE;

subtest 'initial state is pending' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, sub {});

    is($sse->connection_state, 'pending', 'initial connection_state is pending');
    ok(!$sse->is_started, 'is_started is false');
    ok(!$sse->is_closed, 'is_closed is false');
};

subtest 'state transitions' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, sub {});

    $sse->_set_state('started');
    is($sse->connection_state, 'started', 'connection_state is started');
    ok($sse->is_started, 'is_started is true');
    ok(!$sse->is_closed, 'is_closed is false');

    $sse->_set_closed;
    is($sse->connection_state, 'closed', 'connection_state is closed');
    ok(!$sse->is_started, 'is_started is false after close');
    ok($sse->is_closed, 'is_closed is true');
};

done_testing;
