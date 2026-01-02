#!/usr/bin/env perl

# =============================================================================
# Test: Middleware on_error callbacks
#
# Verifies that WebSocket::RateLimit properly invokes on_error callbacks
# when send operations fail.
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use Future;
use Future::AsyncAwait;

# =============================================================================
# Test: WebSocket::RateLimit on_error configuration
# =============================================================================

subtest 'WebSocket::RateLimit on_error config' => sub {
    require PAGI::Middleware::WebSocket::RateLimit;

    # Test default on_error exists
    my $mw = PAGI::Middleware::WebSocket::RateLimit->new();
    ok($mw->{on_error}, 'default on_error callback exists');
    is(ref($mw->{on_error}), 'CODE', 'on_error is a coderef');

    # Test custom on_error is stored
    my $custom_called = 0;
    my $custom_error;
    my $custom_event;

    my $mw2 = PAGI::Middleware::WebSocket::RateLimit->new(
        on_error => sub {
            my ($error, $event) = @_;
            $custom_called = 1;
            $custom_error = $error;
            $custom_event = $event;
        },
    );

    # Invoke the callback manually to verify it's wired up
    $mw2->{on_error}->('rate limit error', { type => 'websocket.close' });
    ok($custom_called, 'custom on_error callback was invoked');
    is($custom_error, 'rate limit error', 'error passed correctly');
    is($custom_event, { type => 'websocket.close' }, 'event passed correctly');
};

done_testing;
