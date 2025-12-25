#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use lib 'lib';
use PAGI::SSE;

subtest 'last_event_id returns header value' => sub {
    my $scope = {
        type    => 'sse',
        headers => [
            ['last-event-id', '42'],
        ],
    };

    my $sse = PAGI::SSE->new($scope, sub {}, sub {});

    is($sse->last_event_id, '42', 'returns last-event-id header');
};

subtest 'last_event_id is case-insensitive' => sub {
    my $scope = {
        type    => 'sse',
        headers => [
            ['Last-Event-ID', 'abc-123'],
        ],
    };

    my $sse = PAGI::SSE->new($scope, sub {}, sub {});

    is($sse->last_event_id, 'abc-123', 'case-insensitive lookup');
};

subtest 'last_event_id returns undef when missing' => sub {
    my $scope = {
        type    => 'sse',
        headers => [],
    };

    my $sse = PAGI::SSE->new($scope, sub {}, sub {});

    is($sse->last_event_id, undef, 'undef when no header');
};

done_testing;
