#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::WebSocket;

subtest 'deny() with extension present sends two events and marks closed' => sub {
    my @sent;
    my $scope = {
        type       => 'websocket',
        headers    => [],
        extensions => { 'websocket.http.response' => {} },
    };
    my $receive = sub { Future->done({ type => 'websocket.connect' }) };
    my $send    = sub { push @sent, $_[0]; Future->done };

    my $ws = PAGI::WebSocket->new($scope, $receive, $send);

    $ws->deny(status => 401, headers => [['x-deny', 'auth']], body => 'no')->get;

    is(scalar @sent, 2, 'two events sent');
    is($sent[0]{type},   'websocket.http.response.start', 'first event is response.start');
    is($sent[0]{status}, 401,                             'status passed through');
    is($sent[0]{headers}, [['x-deny', 'auth']],          'headers passed through');
    is($sent[1]{type},   'websocket.http.response.body',  'second event is response.body');
    is($sent[1]{body},   'no',                            'body passed through');
    ok($ws->is_closed, 'ws marked closed after deny');
};

subtest 'deny() falls back to websocket.close when extension absent' => sub {
    my @sent;
    my $scope = {
        type       => 'websocket',
        headers    => [],
        extensions => {},
    };
    my $receive = sub { Future->done({ type => 'websocket.connect' }) };
    my $send    = sub { push @sent, $_[0]; Future->done };

    my $ws = PAGI::WebSocket->new($scope, $receive, $send);

    $ws->deny(status => 401)->get;

    is(scalar @sent, 1, 'one event sent');
    is($sent[0]{type}, 'websocket.close', 'falls back to websocket.close when unsupported');
    ok($ws->is_closed, 'ws marked closed after deny fallback');
};

subtest 'supports_denial_response() returns 1 when extension present' => sub {
    my $scope_with = {
        type       => 'websocket',
        headers    => [],
        extensions => { 'websocket.http.response' => {} },
    };
    my $ws_with = PAGI::WebSocket->new($scope_with, sub { Future->done }, sub { Future->done });
    ok($ws_with->supports_denial_response, 'returns true when extension advertised');
};

subtest 'supports_denial_response() returns 0 when extension absent' => sub {
    my $scope_without = {
        type       => 'websocket',
        headers    => [],
        extensions => {},
    };
    my $ws_without = PAGI::WebSocket->new($scope_without, sub { Future->done }, sub { Future->done });
    ok(!$ws_without->supports_denial_response, 'returns false when extension absent');
};

subtest 'supports_denial_response() returns 0 when no extensions key' => sub {
    my $scope_none = {
        type    => 'websocket',
        headers => [],
    };
    my $ws_none = PAGI::WebSocket->new($scope_none, sub { Future->done }, sub { Future->done });
    ok(!$ws_none->supports_denial_response, 'returns false when no extensions key');
};

done_testing;
