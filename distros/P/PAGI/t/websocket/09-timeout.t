#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;
use IO::Async::Loop;

use lib 'lib';
use PAGI::WebSocket;

my $loop = IO::Async::Loop->new;

subtest 'receive_with_timeout returns message before timeout' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => 'quick' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->set_loop($loop);
    $ws->accept->get;

    my $event = $ws->receive_with_timeout(5)->get;

    ok($event, 'got event');
    is($event->{text}, 'quick', 'correct message');
};

subtest 'receive_with_timeout returns undef on timeout' => sub {
    my @events = (
        { type => 'websocket.connect' },
    );
    my $idx = 0;

    # receive that never resolves
    my $pending = Future->new;
    my $receive = sub { $idx == 0 ? Future->done($events[$idx++]) : $pending };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->set_loop($loop);
    $ws->accept->get;

    my $event = $ws->receive_with_timeout(0.1)->get;

    is($event, undef, 'returns undef on timeout');
    ok(!$ws->is_closed, 'connection still open after timeout');
};

subtest 'receive_text_with_timeout works' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => 'hello' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->set_loop($loop);
    $ws->accept->get;

    my $text = $ws->receive_text_with_timeout(5)->get;

    is($text, 'hello', 'got text');
};

subtest 'receive_json_with_timeout works' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => '{"key":"value"}' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->set_loop($loop);
    $ws->accept->get;

    my $data = $ws->receive_json_with_timeout(5)->get;

    is($data, { key => 'value' }, 'got decoded JSON');
};

done_testing;
