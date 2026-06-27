#!/usr/bin/env perl
#
# WebSocket Echo Server using PAGI::WebSocket
#
# This example demonstrates the clean PAGI::WebSocket API compared
# to the raw protocol. Compare with examples/04-websocket-echo/app.pl.
#
# Run: pagi-server --app examples/websocket-echo-v2/app.pl --port 5000
# Test: websocat ws://localhost:5000/
#
use strict;
use warnings;
use Future::AsyncAwait;
use PAGI::WebSocket;

my $app = async sub {
    my ($scope, $receive, $send) = @_;

    die if $scope->{type} ne 'websocket';

    my $ws = PAGI::WebSocket->new($scope, $receive, $send);
    await $ws->accept;

    $ws->on_close(sub {
        my ($code) = @_;
        print "Client disconnected: $code\n";
    });

    await $ws->each_text(async sub {
        my ($text) = @_;
        await $ws->send_text("echo: $text");
    });
};

$app;
