#!/usr/bin/env perl
#
# Bidirectional WebSocket with PAGI::Context -- send AND receive at once.
#
# The same full-duplex demo as the raw-protocol examples/18-bidirectional-websocket
# in the PAGI distribution, but written with PAGI::Context. Context unifies the
# protocol behind one object and hands you exactly the pieces this needs:
#
#   - $ctx->each_text(...)            the receive-loop, as a Future that completes
#                                     when the client disconnects
#   - $ctx->send_text_if_connected   a send that is a no-op once the socket is
#                                     closing -- so the concurrent send-loop never
#                                     races the teardown
#   - $ctx->is_connected             a clean loop guard
#
# After accepting, run two concurrent branches and join them with wait_any: a
# client disconnect ends `incoming`, and the idle `outgoing` tick-loop is then
# cancelled. (Contrast the receive-multiplex in PAGI's examples 14/17, where the
# raced future is the live $receive and must NOT be cancelled.)
#
# Run:  pagi-server --app examples/websocket-bidirectional/app.pl --port 5000
# Test: websocat ws://localhost:5000/
#
use strict;
use warnings;
use Future::AsyncAwait;
use Future::IO;
use PAGI::Context;

my $app = async sub {
    my ($scope, $receive, $send) = @_;
    die "Unsupported scope type: $scope->{type}" if ($scope->{type} // '') ne 'websocket';

    my $ctx = PAGI::Context->new($scope, $receive, $send);
    await $ctx->accept;

    # incoming: echo each client message back, uppercased.
    # each_text returns a Future that completes when the client disconnects.
    my $incoming = $ctx->each_text(async sub {
        my ($text) = @_;
        await $ctx->send_text_if_connected("you said: \U$text");
    });

    # outgoing: push a server tick every second, unprompted.
    my $outgoing = (async sub {
        my $n = 0;
        while ($ctx->is_connected) {
            await Future::IO->sleep(1);
            await $ctx->send_text_if_connected("server tick #" . (++$n));
        }
    })->();

    # Run both directions at once; a disconnect ends `incoming`, and wait_any then
    # cancels the still-looping `outgoing`.
    await Future->wait_any($incoming, $outgoing);
};

$app;
