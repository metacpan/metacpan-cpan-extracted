#!/usr/bin/env perl

# =============================================================================
# Test: PAGI::Test::Client scope method field
#
# Per www.mkdn spec:
# - SSE scopes MUST include 'method' (line 624: "reuse the HTTP scope structure")
# - WebSocket scopes do NOT include 'method' (not listed in lines 494-509)
#
# GitHub issue: SSE scope method should be present (defaults to GET)
# =============================================================================

use strict;
use warnings;
use Test2::V0;

use lib 'lib';
use Future::AsyncAwait;
use PAGI::Test::Client;

# =============================================================================
# SSE scope method tests
# =============================================================================

subtest 'SSE scope includes method field (default GET)' => sub {
    my $captured_scope;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;

        if ($scope->{type} eq 'sse') {
            await $send->({ type => 'sse.start', status => 200 });
            await $send->({ type => 'sse.send', data => 'test' });
        }
    };

    my $client = PAGI::Test::Client->new(app => $app);
    $client->sse('/events', sub {
        my ($sse) = @_;
        $sse->receive_event;
    });

    ok defined $captured_scope, 'scope was captured';
    is $captured_scope->{type}, 'sse', 'scope type is sse';
    ok exists $captured_scope->{method}, 'method field exists in SSE scope';
    is $captured_scope->{method}, 'GET', 'method defaults to GET';
};

subtest 'SSE scope supports custom method (POST)' => sub {
    my $captured_scope;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;

        if ($scope->{type} eq 'sse') {
            await $send->({ type => 'sse.start', status => 200 });
            await $send->({ type => 'sse.send', data => 'test' });
        }
    };

    my $client = PAGI::Test::Client->new(app => $app);
    $client->sse('/events', method => 'POST', sub {
        my ($sse) = @_;
        $sse->receive_event;
    });

    ok defined $captured_scope, 'scope was captured';
    is $captured_scope->{type}, 'sse', 'scope type is sse';
    is $captured_scope->{method}, 'POST', 'method is POST when specified';
};

subtest 'SSE method is uppercased' => sub {
    my $captured_scope;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;

        if ($scope->{type} eq 'sse') {
            await $send->({ type => 'sse.start', status => 200 });
            await $send->({ type => 'sse.send', data => 'test' });
        }
    };

    my $client = PAGI::Test::Client->new(app => $app);
    $client->sse('/events', method => 'put', sub {
        my ($sse) = @_;
        $sse->receive_event;
    });

    is $captured_scope->{method}, 'PUT', 'lowercase method is uppercased';
};

# =============================================================================
# WebSocket scope method tests
# =============================================================================

subtest 'WebSocket scope does NOT include method field (per spec)' => sub {
    my $captured_scope;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;

        if ($scope->{type} eq 'websocket') {
            await $send->({ type => 'websocket.accept' });
            await $send->({ type => 'websocket.close', code => 1000 });
        }
    };

    my $client = PAGI::Test::Client->new(app => $app);
    $client->websocket('/ws', sub {
        my ($ws) = @_;
        # Just connect and let it close
    });

    ok defined $captured_scope, 'scope was captured';
    is $captured_scope->{type}, 'websocket', 'scope type is websocket';
    ok !exists $captured_scope->{method}, 'method field does NOT exist in WebSocket scope (per spec)';
};

# =============================================================================
# Verify method is usable for routing (user's use case)
# =============================================================================

subtest 'method can be used for route matching (sse.GET pattern)' => sub {
    my @matches;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;

        # User's pattern: join type and method with dot (if method exists)
        my $route_key = $scope->{type};
        $route_key .= '.' . $scope->{method} if defined $scope->{method};
        push @matches, $route_key;

        if ($scope->{type} eq 'sse') {
            await $send->({ type => 'sse.start', status => 200 });
            await $send->({ type => 'sse.send', data => 'done' });
        }
    };

    my $client = PAGI::Test::Client->new(app => $app);

    # Test GET SSE
    $client->sse('/events', sub {
        my ($sse) = @_;
        $sse->receive_event;
    });

    # Test POST SSE
    $client->sse('/events', method => 'POST', sub {
        my ($sse) = @_;
        $sse->receive_event;
    });

    is \@matches, ['sse.GET', 'sse.POST'], 'SSE route keys include method';
};

subtest 'WebSocket routing uses type only (no method)' => sub {
    my $route_key;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;

        # User's pattern: join type and method with dot (if method exists)
        $route_key = $scope->{type};
        $route_key .= '.' . $scope->{method} if defined $scope->{method};

        if ($scope->{type} eq 'websocket') {
            await $send->({ type => 'websocket.accept' });
            await $send->({ type => 'websocket.close', code => 1000 });
        }
    };

    my $client = PAGI::Test::Client->new(app => $app);
    $client->websocket('/ws', sub {
        my ($ws) = @_;
    });

    is $route_key, 'websocket', 'WebSocket route key is just type (no method suffix)';
};

done_testing;
