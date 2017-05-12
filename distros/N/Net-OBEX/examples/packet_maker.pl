#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{../lib  lib};

use Net::OBEX::Packet::Request;
use Net::OBEX::Packet::Headers;

my $head = Net::OBEX::Packet::Headers->new;
my $req = Net::OBEX::Packet::Request->new;

my $obexftp_target
= $head->make( target  => pack 'H*', 'F9EC7BC4953C11D2984E525400DC9E09');

my $connect_packet = $req->make(
    packet  => 'connect',
    headers => [ $obexftp_target ],
);

# send $conncct_packet down the wire

my $disconnect_packet = $req->make( packet => 'disconnect' );
# this one can go too now.

printf "Connect packet with OBEX FTP Target header is:\n%s\n",
        uc unpack 'H*', $connect_packet;

printf "A disconnect packet is:\n%s\n",
        uc unpack 'H*', $disconnect_packet;

