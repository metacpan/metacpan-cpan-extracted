#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::HTTP;
use Time::HiRes 'time';

use lib 'lib';
use PAGI::Server;

# =============================================================================
# Request Timeout Tests
#
# These tests verify that stalled requests are terminated after the configured
# timeout period. They involve waiting for actual timeouts to occur.
#
# Runs only with RELEASE_TESTING=1 due to timing sensitivity
# =============================================================================

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';
plan skip_all => "Timing-sensitive timeout tests require RELEASE_TESTING=1" unless $ENV{RELEASE_TESTING};

# Test: Request stall timeout closes connection when app doesn't respond
subtest 'request timeout kills stalled request' => sub {
    my $loop = IO::Async::Loop->new;

    my $stall_forever = Future->new;  # Never resolves

    my $server = PAGI::Server->new(
        app => async sub {
            my ($scope, $receive, $send) = @_;

            if ($scope->{type} eq 'lifespan') {
                my $msg = await $receive->();
                if ($msg->{type} eq 'lifespan.startup') {
                    await $send->({ type => 'lifespan.startup.complete' });
                }
                return;
            }

            # Stall forever - never send response
            await $stall_forever;
        },
        port => 0,
        quiet => 1,
        request_timeout => 1,  # 1 second stall timeout
    );
    $loop->add($server);
    $server->listen->get;

    my $port = $server->port;

    my $http = Net::Async::HTTP->new(
        timeout => 5,  # HTTP client timeout (longer than server timeout)
    );
    $loop->add($http);

    my $start = time();
    my $error;
    eval {
        $http->GET("http://127.0.0.1:$port/")->get;
    };
    $error = $@;
    my $elapsed = time() - $start;

    # Should have failed due to connection close
    ok($error, 'Request failed as expected');
    like($error, qr/closed|reset|EOF|Connection/i, 'Error indicates connection was closed');

    # Should have happened within ~1-2 seconds (the request_timeout)
    ok($elapsed >= 1, 'Waited at least 1 second (the timeout)');
    ok($elapsed < 4, 'Did not wait for full HTTP client timeout (5s)');

    $stall_forever->cancel;  # Clean up
    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($http);
};

# Test: Active request (writing data) doesn't timeout
subtest 'active request does not timeout' => sub {
    my $loop = IO::Async::Loop->new;

    my $server = PAGI::Server->new(
        app => async sub {
            my ($scope, $receive, $send) = @_;

            if ($scope->{type} eq 'lifespan') {
                my $msg = await $receive->();
                if ($msg->{type} eq 'lifespan.startup') {
                    await $send->({ type => 'lifespan.startup.complete' });
                }
                return;
            }

            # Slow but active response - sends data every 0.5s
            await $send->({
                type    => 'http.response.start',
                status  => 200,
                headers => [['content-type', 'text/plain']],
            });

            for my $i (1..4) {
                await $loop->delay_future(after => 0.5);
                await $send->({
                    type => 'http.response.body',
                    body => "chunk $i\n",
                    more => ($i < 4 ? 1 : 0),
                });
            }
        },
        port => 0,
        quiet => 1,
        request_timeout => 1,  # 1 second stall timeout
    );
    $loop->add($server);
    $server->listen->get;

    my $port = $server->port;

    my $http = Net::Async::HTTP->new(timeout => 10);
    $loop->add($http);

    my $start = time();
    my $response = $http->GET("http://127.0.0.1:$port/")->get;
    my $elapsed = time() - $start;

    is($response->code, 200, 'Got 200 response');
    like($response->content, qr/chunk 4/, 'Got all chunks');
    ok($elapsed >= 2, 'Took at least 2 seconds (4 chunks * 0.5s)');

    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($http);
};

# Test: request_timeout=0 disables timeout
subtest 'request_timeout=0 disables timeout' => sub {
    my $server = PAGI::Server->new(
        app => async sub {
            my ($scope, $receive, $send) = @_;
            await $send->({ type => 'http.response.start', status => 200, headers => [] });
            await $send->({ type => 'http.response.body', body => 'OK' });
        },
        port => 0,
        quiet => 1,
        request_timeout => 0,  # Disabled
    );

    is($server->{request_timeout}, 0, 'request_timeout is 0 (disabled)');
};

# Test: Default request_timeout is 0 (disabled for performance)
subtest 'default request_timeout is 0 (disabled)' => sub {
    my $server = PAGI::Server->new(
        app => async sub {
            my ($scope, $receive, $send) = @_;
            await $send->({ type => 'http.response.start', status => 200, headers => [] });
            await $send->({ type => 'http.response.body', body => 'OK' });
        },
        port => 0,
        quiet => 1,
    );

    is($server->{request_timeout}, 0, 'default request_timeout is 0 (disabled for performance)');
};

done_testing;
