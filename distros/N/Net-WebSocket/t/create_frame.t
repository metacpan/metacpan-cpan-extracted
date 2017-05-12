#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Module::Load ();

use Net::WebSocket::Frame ();

my $NWF = 'Net::WebSocket::Frame';

my @tests = (
    [
        'bare ping',
        ['ping' ],
        "\x89\x00",
    ],
    [
        'ping with payload',
        [ 'ping', payload_sr => \'Ping!' ],
        "\x89\x05Ping!",
    ],
    [
        'bare pong',
        [ 'pong' ],
        "\x8a\x00",
    ],
    [
        'pong with payload',
        [ 'pong', payload_sr => \'Pong!' ],
        "\x8a\x05Pong!",
    ],
);

plan tests => 0 + @tests;

for my $t (@tests) {
    my ($type, @args) = @{ $t->[1] };
    my $class = "Net::WebSocket::Frame::$type";
    Module::Load::load($class);

    my $frame = $class->new( @args );

    is(
        $frame->to_bytes(),
        $t->[2],
        $t->[0],
    ) or diag explain [ $frame, $t->[2] ];
}
