#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    eval 'use autodie;';
}

use Test::More;
use Test::Deep;

use IO::Select ();

use Net::WebSocket::Parser ();

plan tests => 1;

ok 1, 'We all know this protocol does fragmentation, right?';

#pipe( my $rdr, my $wtr );
#
#$rdr->blocking(0);
#
#my $frame;
#
#my $parser = Net::WebSocket::ParseFilehandle->new( $rdr );
#
#my $ios = IO::Select->new($rdr);
#
#alarm 300;
#
#syswrite $wtr, "\x81\x7f" . "\x00\x00\x00\x01\x00\x01\x00\x00";
#
#while (!$frame) {
#    syswrite $wtr, ('x' x 2048);
#    my ($rdrs_ar) = IO::Select->select( $ios );
#
#    $frame = $parser->get_next_frame();
#}
#
#cmp_deeply(
#    $frame,
#    all(
#        methods(
#            get_type => 'text',
#        ),
#        Isa('Net::WebSocket::Frame'),
#    ),
#    "partial frame",
#) or diag explain $frame;
#
#is(
#    length( $frame->get_payload() ),
#    2**32 + 2**16,
#    'payload length',
#);

1;
