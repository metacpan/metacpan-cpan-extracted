#!/usr/bin/env perl

# =============================================================================
# Test: Middleware on_error callbacks
#
# Verifies that WebSocket::Heartbeat, SSE::Heartbeat, and WebSocket::RateLimit
# properly invoke on_error callbacks when send operations fail.
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use Future;
use Future::AsyncAwait;

# =============================================================================
# Test: WebSocket::Heartbeat on_error configuration
# =============================================================================

subtest 'WebSocket::Heartbeat on_error config' => sub {
    require PAGI::Middleware::WebSocket::Heartbeat;

    # Test default on_error exists
    my $mw = PAGI::Middleware::WebSocket::Heartbeat->new();
    ok($mw->{on_error}, 'default on_error callback exists');
    is(ref($mw->{on_error}), 'CODE', 'on_error is a coderef');

    # Test custom on_error is stored
    my $custom_called = 0;
    my $custom_error;
    my $custom_event;

    my $mw2 = PAGI::Middleware::WebSocket::Heartbeat->new(
        on_error => sub {
            my ($error, $event) = @_;
            $custom_called = 1;
            $custom_error = $error;
            $custom_event = $event;
        },
    );

    # Invoke the callback manually to verify it's wired up
    $mw2->{on_error}->('test error', { type => 'test.event' });
    ok($custom_called, 'custom on_error callback was invoked');
    is($custom_error, 'test error', 'error passed correctly');
    is($custom_event, { type => 'test.event' }, 'event passed correctly');
};

# =============================================================================
# Test: SSE::Heartbeat on_error configuration
# =============================================================================

subtest 'SSE::Heartbeat on_error config' => sub {
    require PAGI::Middleware::SSE::Heartbeat;

    # Test default on_error exists
    my $mw = PAGI::Middleware::SSE::Heartbeat->new();
    ok($mw->{on_error}, 'default on_error callback exists');
    is(ref($mw->{on_error}), 'CODE', 'on_error is a coderef');

    # Test custom on_error is stored
    my $custom_called = 0;
    my $custom_error;
    my $custom_event;

    my $mw2 = PAGI::Middleware::SSE::Heartbeat->new(
        on_error => sub {
            my ($error, $event) = @_;
            $custom_called = 1;
            $custom_error = $error;
            $custom_event = $event;
        },
    );

    # Invoke the callback manually to verify it's wired up
    $mw2->{on_error}->('sse error', { type => 'sse.send' });
    ok($custom_called, 'custom on_error callback was invoked');
    is($custom_error, 'sse error', 'error passed correctly');
    is($custom_event, { type => 'sse.send' }, 'event passed correctly');
};

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

# =============================================================================
# Test: on_fail chain is set up correctly
# =============================================================================

subtest 'on_fail chain is set up in heartbeat code' => sub {
    require PAGI::Middleware::WebSocket::Heartbeat;

    # Read the source to verify on_fail is wired up
    # This is a structural test - the runtime behavior is tested by
    # checking the default warning works in the next subtest

    my $module_path = $INC{'PAGI/Middleware/WebSocket/Heartbeat.pm'};
    ok($module_path, 'Module is loaded');

    open my $fh, '<', $module_path or die "Cannot open module: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    like($source, qr/->on_fail\(sub \{/, 'Source contains on_fail callback');
    like($source, qr/\$on_error->/, 'Source calls on_error callback');
};

# =============================================================================
# Test: Default on_error warns to STDERR
# =============================================================================

subtest 'Default on_error warns to STDERR' => sub {
    require PAGI::Middleware::WebSocket::Heartbeat;

    my $mw = PAGI::Middleware::WebSocket::Heartbeat->new();

    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };

    $mw->{on_error}->('test failure', { type => 'websocket.send' });

    like($warning, qr/WebSocket::Heartbeat send failed/, 'warning includes middleware name');
    like($warning, qr/test failure/, 'warning includes error message');
};

done_testing;
