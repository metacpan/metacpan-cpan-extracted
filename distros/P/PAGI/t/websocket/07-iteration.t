#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;
use JSON::MaybeXS;

use lib 'lib';
use PAGI::WebSocket;

subtest 'each_message iterates until disconnect' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => 'msg1' },
        { type => 'websocket.receive', text => 'msg2' },
        { type => 'websocket.receive', text => 'msg3' },
        { type => 'websocket.disconnect', code => 1000 },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my @received;
    $ws->each_message(async sub {
        my ($event) = @_;
        push @received, $event->{text};
    })->get;

    is(\@received, ['msg1', 'msg2', 'msg3'], 'received all messages');
    ok($ws->is_closed, 'connection closed after iteration');
};

subtest 'each_text iterates text frames' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', bytes => "\x00" },  # skipped
        { type => 'websocket.receive', text => 'hello' },
        { type => 'websocket.receive', text => 'world' },
        { type => 'websocket.disconnect', code => 1000 },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my @received;
    $ws->each_text(async sub {
        my ($text) = @_;
        push @received, $text;
    })->get;

    is(\@received, ['hello', 'world'], 'received text messages only');
};

subtest 'each_json iterates and decodes' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => '{"n":1}' },
        { type => 'websocket.receive', text => '{"n":2}' },
        { type => 'websocket.disconnect', code => 1000 },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    my @received;
    $ws->each_json(async sub {
        my ($data) = @_;
        push @received, $data->{n};
    })->get;

    is(\@received, [1, 2], 'received and decoded JSON');
};

subtest 'callback can send responses' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => 'ping' },
        { type => 'websocket.disconnect', code => 1000 },
    );
    my $idx = 0;
    my @sent;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { push @sent, $_[0]; Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;
    @sent = ();

    $ws->each_text(async sub {
        my ($text) = @_;
        await $ws->send_text("pong: $text");
    })->get;

    is($sent[0]{text}, 'pong: ping', 'callback sent response');
};

subtest 'exception in callback propagates' => sub {
    my @events = (
        { type => 'websocket.connect' },
        { type => 'websocket.receive', text => 'trigger' },
    );
    my $idx = 0;
    my $receive = sub { Future->done($events[$idx++]) };
    my $send = sub { Future->done };

    my $scope = { type => 'websocket', headers => [] };
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    $ws->accept->get;

    like(
        dies {
            $ws->each_text(async sub {
                die "Intentional error";
            })->get;
        },
        qr/Intentional error/,
        'exception propagates'
    );
};

done_testing;
