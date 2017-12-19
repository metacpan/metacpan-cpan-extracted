#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 12;

use File::Temp ();

use IO::Framed;

use Net::WebSocket::Parser;
use Net::WebSocket::Mask ();

my @tests = (
    [
        'empty',
        "\x88\0",
        [ undef, q<> ],
    ],
    [
        'just status',
        "\x88\x02\x03\xe9",
        [ 1001, q<> ],
    ],
    [
        'status with message',
        "\x88\x08\x03\xeaHello.",
        [ 1002, 'Hello.' ],
    ],
);

for my $t (@tests) {
    my $raw = $t->[1];

    #NB: Not a strong enough source of entropy for production!!
    my $mask = pack 'C4', map { int rand 256 } 1 .. 4;

    my $raw_masked = $raw;
    Net::WebSocket::Mask::apply( \substr($raw_masked, 2), $mask );
    substr( $raw_masked, 2, 0 ) = $mask;
    substr( $raw_masked, 1, 1 ) |= "\x80";

    for my $tt ( [ unmasked => $raw ], [ masked => $raw_masked ] ) {
        my $bin = $tt->[1];

        my ( $bfh, $bpath ) = File::Temp::tempfile( CLEANUP => 1 );
        syswrite( $bfh, $tt->[1] );
        close $bfh;

        open my $sfh, '<', $bpath;
        my $sr_parse = Net::WebSocket::Parser->new( IO::Framed->new($sfh) );

        my ($fh, $path) = File::Temp::tempfile( CLEANUP => 1 );
        print {$fh} $bin or die $!;
        close $fh;

        open my $rfh, '<', $path;
        my $fh_parse = Net::WebSocket::Parser->new( IO::Framed->new($rfh) );

        for my $ttt ( [ scalar => $sr_parse ], [ filehandle => $fh_parse ] ) {
            my $frame = $ttt->[1]->get_next_frame();

            is_deeply(
                [ $frame->get_code_and_reason() ],
                $t->[2],
                "$t->[0], $tt->[0], $ttt->[0] - get_code_and_reason()",
            );
        }
    }
}
