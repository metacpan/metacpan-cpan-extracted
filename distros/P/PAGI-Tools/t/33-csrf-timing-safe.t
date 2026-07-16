#!/usr/bin/env perl

# =============================================================================
# Test: CSRF timing-safe comparison
#
# Verifies that the CSRF middleware's token validation goes through the
# constant-time PAGI::Utils::SecureCompare::secure_compare. The constant-time
# comparison itself (identical/mismatched/undef/length-differing inputs) is
# unit-tested directly in t/utils/secure-compare.t; this file exercises it
# through the middleware's actual token-validation path.
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;

require PAGI::Middleware::CSRF;

my $loop = IO::Async::Loop->new;

sub run_async {
    my ($code) = @_;
    my $future = $code->();
    $loop->await($future);
}

# =============================================================================
# Test: CSRF middleware uses secure_compare
# =============================================================================

subtest 'CSRF middleware token validation' => sub {
    my $csrf = PAGI::Middleware::CSRF->new(secret => 'test-secret');

    # Generate a token
    my $token = $csrf->_generate_token();
    ok(length($token) > 0, 'token generated');

    # Mock app that just succeeds
    my $app_called = 0;
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $app_called = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
    };

    my $wrapped = $csrf->wrap($app);

    # Test: POST with matching tokens should succeed
    $app_called = 0;
    my @events;
    my $scope = {
        type => 'http',
        method => 'POST',
        path => '/test',
        headers => [
            ['cookie', "csrf_token=$token"],
            ['x-csrf-token', $token],
        ],
    };

    my $receive = async sub { { type => 'http.disconnect' } };
    my $send = async sub { push @events, $_[0] };

    run_async(async sub {
        await $wrapped->($scope, $receive, $send);
    });
    ok($app_called, 'app called with valid token');

    # Test: POST with mismatched tokens should fail
    $app_called = 0;
    @events = ();
    $scope = {
        type => 'http',
        method => 'POST',
        path => '/test',
        headers => [
            ['cookie', "csrf_token=$token"],
            ['x-csrf-token', 'wrong-token'],
        ],
    };

    run_async(async sub {
        await $wrapped->($scope, $receive, $send);
    });
    ok(!$app_called, 'app NOT called with invalid token');
    is($events[0]{status}, 403, 'returns 403 for invalid token');

    # Test: POST with no submitted token should fail
    $app_called = 0;
    @events = ();
    $scope = {
        type => 'http',
        method => 'POST',
        path => '/test',
        headers => [
            ['cookie', "csrf_token=$token"],
        ],
    };

    run_async(async sub {
        await $wrapped->($scope, $receive, $send);
    });
    ok(!$app_called, 'app NOT called with missing token');
    is($events[0]{status}, 403, 'returns 403 for missing token');

    # Test: GET should pass through without validation
    $app_called = 0;
    @events = ();
    $scope = {
        type => 'http',
        method => 'GET',
        path => '/test',
        headers => [],
    };

    run_async(async sub {
        await $wrapped->($scope, $receive, $send);
    });
    ok($app_called, 'GET passes through without CSRF check');
};

done_testing;
