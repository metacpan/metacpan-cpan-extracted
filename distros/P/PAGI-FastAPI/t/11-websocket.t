#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use JSON::PP qw(decode_json);
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new(title => 'WebSocket Test App');

# Simple echo WebSocket endpoint
$app->websocket('/ws/echo',
    handler => async sub ($ws, $deps) {
        await $ws->accept;

        while (my $msg = await $ws->receive_text) {
            await $ws->send_text("Echo: $msg");
        }
    }
);

# WebSocket endpoint with path params, JSON messaging, and explicit close
$app->websocket('/ws/chat/{room}',
    handler => async sub ($ws, $deps) {
        my $room = $ws->path_params->{room};
        await $ws->accept;

        my $data = await $ws->receive_json;
        if ($data->{action} eq 'ping') {
            await $ws->send_json({ room => $room, status => 'pong' });
        }

        await $ws->close(1000, "Done");
    }
);

my $pagi_app = $app->to_app;

subtest 'Valid WebSocket Handshake and Echo Flow' => sub {
    my $scope = {
        type         => 'websocket',
        path         => '/ws/echo',
        query_string => '',
        headers      => [],
    };

    # Queue of incoming client events
    my @incoming_events = (
        { type => 'websocket.receive', text => 'Hello Perl' },
        { type => 'websocket.disconnect', code => 1000 },
    );

    my @sent_events;

    my $receive = async sub {
        return shift @incoming_events;
    };

    my $send = async sub ($event) {
        push @sent_events, $event;
    };

    # Resolve async execution with ->get
    $pagi_app->($scope, $receive, $send)->get;

    is scalar(@sent_events), 2, 'Received two outgoing events';
    is $sent_events[0]->{type}, 'websocket.accept', 'First event was websocket.accept';
    is $sent_events[1]->{type}, 'websocket.send', 'Second event was websocket.send';
    is $sent_events[1]->{text}, 'Echo: Hello Perl', 'Echo text payload is correct';
};

subtest 'WebSocket Route with Path Params, JSON Payload, and Handshake Close' => sub {
    my $scope = {
        type         => 'websocket',
        path         => '/ws/chat/lobby',
        query_string => '',
        headers      => [],
    };

    my @incoming_events = (
        { type => 'websocket.receive', text => '{"action":"ping"}' },
    );

    my @sent_events;

    my $receive = async sub {
        return shift @incoming_events // { type => 'websocket.disconnect', code => 1000 };
    };

    my $send = async sub ($event) {
        push @sent_events, $event;
    };

    $pagi_app->($scope, $receive, $send)->get;

    is scalar(@sent_events), 3, 'Received accept, json message, and close events';
    is $sent_events[0]->{type}, 'websocket.accept', 'Handshake accepted';

    is $sent_events[1]->{type}, 'websocket.send', 'JSON message event sent';
    my $data = decode_json($sent_events[1]->{text});
    is $data->{room}, 'lobby', 'Path parameter accessible in WebSocket handler';
    is $data->{status}, 'pong', 'JSON response payload is correct';

    is $sent_events[2]->{type}, 'websocket.close', 'Connection closed cleanly';
    is $sent_events[2]->{code}, 1000, 'Close code 1000 sent';
};

subtest '4004 Close Code on Non-Existent Route' => sub {
    my $scope = {
        type         => 'websocket',
        path         => '/ws/nonexistent',
        query_string => '',
        headers      => [],
    };

    my @sent_events;

    my $receive = async sub { return { type => 'websocket.disconnect' } };
    my $send    = async sub ($event) {
        push @sent_events, $event;
    };

    $pagi_app->($scope, $receive, $send)->get;

    is scalar(@sent_events), 1, 'Only one event sent for unmatched route';
    is $sent_events[0]->{type}, 'websocket.close', 'Close event issued on non-existent route';
    is $sent_events[0]->{code}, 4004, 'Close code 4004 Not Found returned';
};

done_testing;
