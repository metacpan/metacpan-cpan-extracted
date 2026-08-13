#!/usr/bin/env perl

use v5.38;
use Test::More;
use experimental 'class';

use PAGI::FastAPI::Response::SSE;
use Future;
use Future::AsyncAwait;

class MockPagiSSEChannel {
    field $events_sent = [];
    field $state       = 'open';

    async method send ($event) {
        push @$events_sent, $event;
        if ($event->{type} eq 'sse.close') {
            $state = 'closed';
        }
    }

    async method receive () {
        return Future->new;
    }

    method get_sent_events () { return $events_sent }
}

subtest 'PAGI::SSE Dispatcher - Connection Initialization' => sub {
    my $mock_channel = MockPagiSSEChannel->new;

    my $scope   = { type => 'sse', path => '/stream' };
    my $receive = sub { $mock_channel->receive };
    my $send    = sub ($evt) { $mock_channel->send($evt) };

    my $response = PAGI::FastAPI::Response::SSE->new(
        status    => 200,
        headers   => [ ['x-custom-header' => 'test-val'] ],
        generator => async sub ($sse) {
            await $sse->send("hello world");
            await $sse->close(reason => 'test_done');
        },
    );

    $response->dispatch($scope, $receive, $send)->get;

    my $sent = $mock_channel->get_sent_events;

    # 1. Verify sse.start event headers
    is($sent->[0]{type}, 'sse.start', 'First event sent is sse.start');
    is($sent->[0]{status}, 200, 'Status code 200 passed through');

    my %headers = map { $_->[0] => $_->[1] } @{$sent->[0]{headers}};
    is($headers{'x-accel-buffering'}, 'no', 'Nginx buffering header disabled');
    is($headers{'x-custom-header'}, 'test-val', 'Custom headers merged correctly');

    # 2. Verify data payload
    is($sent->[1]{type}, 'sse.send', 'Second event sent is sse.send');
    is($sent->[1]{data}, 'hello world', 'Data string matched expected payload');

    # 3. Verify close event
    is($sent->[2]{type}, 'sse.close', 'Final event sent is sse.close');
    is($sent->[2]{reason}, 'test_done', 'Close reason passed to transport');
};

subtest 'PAGI::SSE Features - JSON, Custom Events, and Keepalives' => sub {
    my $mock_channel = MockPagiSSEChannel->new;

    my $scope   = { type => 'sse', path => '/live' };
    my $receive = sub { $mock_channel->receive };
    my $send    = sub ($evt) { $mock_channel->send($evt) };

    my $response = PAGI::FastAPI::Response::SSE->new(
        generator => async sub ($sse) {
            # Send keepalive ping request
            await $sse->keepalive(15);

            # Send structured JSON event
            await $sse->send_event(
                event => 'token',
                id    => 'msg-1',
                data  => { word => 'PAGI', score => 99 },
            );

            await $sse->close;
        },
    );

    $response->dispatch($scope, $receive, $send)->get;

    my $sent = $mock_channel->get_sent_events;

    # Assert keepalive registration
    is($sent->[1]{type}, 'sse.keepalive', 'Keepalive event issued');
    is($sent->[1]{interval}, 15, 'Keepalive interval set to 15 seconds');

    # Assert structured event
    is($sent->[2]{type}, 'sse.send', 'Structured event sent');
    is($sent->[2]{event}, 'token', 'Event type specified');
    is($sent->[2]{id}, 'msg-1', 'Event ID set');
    like($sent->[2]{data}, qr/"word":"PAGI"/, 'Data automatically encoded as JSON');
};

subtest 'PAGI::SSE Cleanup & Error Handling' => sub {
    my $mock_channel = MockPagiSSEChannel->new;

    my $scope   = { type => 'sse', path => '/stream' };
    my $receive = sub { $mock_channel->receive };
    my $send    = sub ($evt) { $mock_channel->send($evt) };

    my $cleanup_ran = 0;

    my $response = PAGI::FastAPI::Response::SSE->new(
        generator => async sub ($sse) {
            # Register close callback
            $sse->on_close(sub ($s, $reason) {
                $cleanup_ran = 1;
            });

            await $sse->send("ping");
            await $sse->close(reason => 'app_closed');
        },
    );

    $response->dispatch($scope, $receive, $send)->get;

    ok($cleanup_ran, 'on_close lifecycle hook executed upon completion');
};

done_testing;
