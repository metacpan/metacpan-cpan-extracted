#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    eval 'use autodie';
}

use Test::More;
plan tests => 5;

use File::Temp ();
use File::Slurp ();
use IO::Framed ();

use Net::WebSocket::Endpoint::Server ();
use Net::WebSocket::Frame::ping ();
use Net::WebSocket::Frame::pong ();
use Net::WebSocket::Frame::text ();
use Net::WebSocket::Parser ();

pipe my $rdr, my $wtr;

syswrite( $wtr, Net::WebSocket::Frame::ping->new(
    payload => 'hahaha',
)->to_bytes() );

syswrite( $wtr, Net::WebSocket::Frame::text->new(
    payload => 'Real text.',
)->to_bytes() );

close $wtr;

my $frdr = IO::Framed::Read->new($rdr);
$frdr->allow_empty_read();

my ($out_fh, $out_path) = File::Temp::tempfile( CLEANUP => 1 );
my $fwtr = IO::Framed::Write->new($out_fh);

my $ept = Net::WebSocket::Endpoint::Server->new(
    parser => Net::WebSocket::Parser->new($frdr),
    out => $fwtr,
);

#----------------------------------------------------------------------

is(
    $ept->get_next_message(),
    undef,
    'get_next_message() when the input was just a ping',
);

is(
    File::Slurp::read_file($out_path),
    Net::WebSocket::Frame::pong->new( payload => 'hahaha' )->to_bytes(),
    'first ping input sends a pong',
);

my $msg = $ept->get_next_message();
isa_ok(
    $msg,
    'Net::WebSocket::Message',
    'get_next_message() response',
) or diag explain [$msg];
is( $msg->get_payload(), 'Real text.', '… and the payload is right' );

$msg = $ept->get_next_message();
is(
    $msg,
    q<>,
    'get_next_message() when the input is at EOF',
);
