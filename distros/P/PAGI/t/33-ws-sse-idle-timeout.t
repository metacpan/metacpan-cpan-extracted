#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::HTTP;
use Protocol::WebSocket::Client;
use Time::HiRes 'time';

use lib 'lib';
use PAGI::Server;

# =============================================================================
# WebSocket/SSE Idle Timeout Tests
#
# These tests verify that idle WebSocket and SSE connections are terminated
# after the configured timeout period. They involve waiting for actual
# timeouts to occur.
#
# Runs only with RELEASE_TESTING=1 due to timing sensitivity
# =============================================================================

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';
plan skip_all => "Timing-sensitive timeout tests require RELEASE_TESTING=1" unless $ENV{RELEASE_TESTING};

# Test: WebSocket idle timeout closes connection
subtest 'websocket idle timeout closes connection' => sub {
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

            if ($scope->{type} eq 'websocket') {
                my $event = await $receive->();
                return unless $event->{type} eq 'websocket.connect';

                await $send->({ type => 'websocket.accept' });

                # Wait for messages or disconnect
                while (1) {
                    my $msg = await $receive->();
                    last if $msg->{type} eq 'websocket.disconnect';
                }
            }
        },
        port => 0,
        quiet => 1,
        ws_idle_timeout => 1,  # 1 second idle timeout for WebSocket
    );
    $loop->add($server);
    $server->listen->get;

    my $port = $server->port;

    # Create WebSocket connection
    my $ws_closed = 0;
    my $close_code;
    my $ws_stream;

    my $ws = Protocol::WebSocket::Client->new(url => "ws://127.0.0.1:$port/");

    my $stream = IO::Async::Stream->new(
        on_read => sub {
            my ($self, $buffref, $eof) = @_;
            $ws->read($$buffref);
            $$buffref = '';

            if ($eof) {
                $ws_closed = 1;
            }
            return 0;
        },
        on_closed => sub {
            $ws_closed = 1;
        },
    );
    $ws_stream = $stream;

    $ws->on(write => sub {
        my ($client, $buf) = @_;
        $stream->write($buf);
    });

    $ws->on(connect => sub {
        # Connected, now just wait and do nothing (trigger idle timeout)
    });

    $ws->on(close => sub {
        my ($client, $code, $reason) = @_;
        $close_code = $code;
        $ws_closed = 1;
    });

    # Connect
    require IO::Socket::INET;
    my $socket = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
    ) or die "Cannot connect: $!";

    $stream->configure(handle => $socket);
    $loop->add($stream);

    $ws->connect;

    # Wait for idle timeout (should close within ~2 seconds)
    my $start = time();
    my $timeout = $loop->delay_future(after => 3);

    while (!$ws_closed && !$timeout->is_ready) {
        $loop->loop_once(0.1);
    }

    my $elapsed = time() - $start;

    ok($ws_closed, 'WebSocket connection was closed');
    ok($elapsed >= 1, 'Waited at least 1 second (the timeout)');
    ok($elapsed < 3, 'Closed before 3 seconds (idle timeout worked)');

    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($stream) if $stream->loop;
};

# Test: SSE idle timeout closes connection
subtest 'sse idle timeout closes connection' => sub {
    my $loop = IO::Async::Loop->new;

    my $stall_forever = Future->new;

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

            if ($scope->{type} eq 'sse') {
                await $send->({
                    type    => 'sse.start',
                    status  => 200,
                    headers => [],
                });

                # Just wait, don't send anything (trigger idle timeout)
                await $stall_forever;
            }
        },
        port => 0,
        quiet => 1,
        sse_idle_timeout => 1,  # 1 second idle timeout for SSE
    );
    $loop->add($server);
    $server->listen->get;

    my $port = $server->port;

    my $http = Net::Async::HTTP->new(timeout => 5);
    $loop->add($http);

    my $start = time();
    my $error;
    eval {
        $http->do_request(
            method => 'GET',
            uri    => "http://127.0.0.1:$port/events",
            headers => { Accept => 'text/event-stream' },
        )->get;
    };
    $error = $@;
    my $elapsed = time() - $start;

    # Should have failed due to connection close
    ok($error, 'SSE request failed as expected');
    ok($elapsed >= 1, 'Waited at least 1 second (the timeout)');
    ok($elapsed < 4, 'Closed before 4 seconds (idle timeout worked)');

    $stall_forever->cancel;
    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($http);
};

# Test: WebSocket with activity doesn't timeout
subtest 'websocket with activity does not timeout' => sub {
    my $loop = IO::Async::Loop->new;

    my $messages_received = 0;

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

            if ($scope->{type} eq 'websocket') {
                my $event = await $receive->();
                return unless $event->{type} eq 'websocket.connect';

                await $send->({ type => 'websocket.accept' });

                # Send messages every 0.3 seconds for 1.5 seconds
                for my $i (1..5) {
                    await $loop->delay_future(after => 0.3);
                    await $send->({
                        type => 'websocket.send',
                        text => "message $i",
                    });
                }

                # Wait for disconnect
                while (1) {
                    my $msg = await $receive->();
                    last if $msg->{type} eq 'websocket.disconnect';
                }
            }
        },
        port => 0,
        quiet => 1,
        ws_idle_timeout => 1,  # 1 second idle timeout
    );
    $loop->add($server);
    $server->listen->get;

    my $port = $server->port;

    # Create WebSocket connection
    my $ws_closed = 0;
    my $ws = Protocol::WebSocket::Client->new(url => "ws://127.0.0.1:$port/");

    my $stream = IO::Async::Stream->new(
        on_read => sub {
            my ($self, $buffref, $eof) = @_;
            $ws->read($$buffref);
            $$buffref = '';

            if ($eof) {
                $ws_closed = 1;
            }
            return 0;
        },
        on_closed => sub {
            $ws_closed = 1;
        },
    );

    $ws->on(write => sub {
        my ($client, $buf) = @_;
        $stream->write($buf);
    });

    $ws->on(read => sub {
        my ($client, $buf) = @_;
        $messages_received++ if $buf;
    });

    $ws->on(close => sub {
        $ws_closed = 1;
    });

    # Connect
    require IO::Socket::INET;
    my $socket = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
    ) or die "Cannot connect: $!";

    $stream->configure(handle => $socket);
    $loop->add($stream);

    $ws->connect;

    # Wait for messages
    my $start = time();
    my $timeout = $loop->delay_future(after => 3);

    while (!$ws_closed && $messages_received < 5 && !$timeout->is_ready) {
        $loop->loop_once(0.1);
    }

    my $elapsed = time() - $start;

    ok($messages_received >= 5, 'Received all 5 messages');
    ok($elapsed >= 1.5, 'Took at least 1.5 seconds (5 * 0.3s)');

    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($stream) if $stream->loop;
};

# Test: Default timeouts
subtest 'default ws and sse idle timeouts' => sub {
    my $server = PAGI::Server->new(
        app => async sub {
            my ($scope, $receive, $send) = @_;
            await $send->({ type => 'http.response.start', status => 200, headers => [] });
            await $send->({ type => 'http.response.body', body => 'OK' });
        },
        port => 0,
        quiet => 1,
    );

    # Default should be 0 (disabled) or some reasonable value
    # For now, default is 0 (disabled, rely on middleware like WebSocket::Heartbeat)
    is($server->{ws_idle_timeout}, 0, 'default ws_idle_timeout is 0 (disabled)');
    is($server->{sse_idle_timeout}, 0, 'default sse_idle_timeout is 0 (disabled)');
};

done_testing;
