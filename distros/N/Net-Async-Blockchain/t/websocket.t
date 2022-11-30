#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use IO::Async::Test;
use IO::Async::Loop;
use Net::Async::WebSocket::Server;
use Net::Async::Blockchain::Client::Websocket;
use JSON::MaybeUTF8 qw(encode_json_utf8 decode_json_utf8);

my $loop = IO::Async::Loop->new;
testing_loop($loop);

my @serverframes;
my $reconnections = 0;

my $server = Net::Async::WebSocket::Server->new(
    on_client => sub {
        my (undef, $client) = @_;

        $reconnections += 1;

        $client->configure(
            on_text_frame => sub {
                my ($self, $frame) = @_;
                push @serverframes, $frame;
            },
        );
    },
);

$loop->add($server);

my $ws_client;
$server->listen(
    service => 0,
)->on_done(
    sub {
        my ($listener) = @_;
        my $socket = $listener->read_handle;

        my $host    = $socket->sockhost;
        my $service = $socket->sockport;

        $ws_client = Net::Async::Blockchain::Client::Websocket->new(
            endpoint => sprintf("ws://%s:%s", $host, $service),
        );

        $loop->add($ws_client);
    });

wait_for { $ws_client };

$ws_client->eth_subscribe('newHeads')->get;

wait_for { @serverframes };

is_deeply(decode_json_utf8(shift(@serverframes))->{params}, ["newHeads"], 'received subscription');

done_testing;
