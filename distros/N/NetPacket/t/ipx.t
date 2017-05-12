#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 14;

use_ok 'NetPacket::IPX';

my $packet = ""
	."\xFF\xFF" # "checksum"
	."\x00\x2A" # header + data length
	."\x64"     # Traffic Control
	."\x05"     # Packet type
	
	."\x46\x35\x57\xFF"         # Destination network
	."\x01\x23\x45\x67\x89\xAB" # Destination node
	."\xEE\xAA"                 # Destination socket
	
	."\xDE\xFF\x00\x01"         # Source network
	."\xCD\xEF\x01\x23\x45\x67" # Source node
	."\xAA\xAA"                 # Source socket
	
	."\x00some \n\xFFdata";

{
	my $ipx = NetPacket::IPX->decode($packet);
	
	isa_ok($ipx, "NetPacket::IPX");
	
	is($ipx->{tc},   0x64, "NetPacket::IPX->decode() decodes the tc field");
	is($ipx->{type}, 0x05, "NetPacket::IPX->decode() decodes the type field");
	
	is($ipx->{dest_network}, "46:35:57:FF",       "NetPacket::IPX->decode() decodes the destination network field");
	is($ipx->{dest_node},    "01:23:45:67:89:AB", "NetPacket::IPX->decode() decodes the destination node field");
	is($ipx->{dest_socket},  0xEEAA,              "NetPacket::IPX->decode() decodes the destination socket field");
	
	is($ipx->{src_network}, "DE:FF:00:01",       "NetPacket::IPX->decode() decodes the source network field");
	is($ipx->{src_node},    "CD:EF:01:23:45:67", "NetPacket::IPX->decode() decodes the source node field");
	is($ipx->{src_socket},  0xAAAA,              "NetPacket::IPX->decode() decodes the source socket field");
	
	is($ipx->{data}, "\x00some \n\xFFdata", "NetPacket::IPX->decode() extracts the packet payload");
}

{
	my $ipx = NetPacket::IPX->new(
		tc   => 0x64,
		type => 0x05,
		
		dest_network => "46:35:57:fF",
		dest_node    => "1:23:45:67:89:Ab",
		dest_socket  => 0xEEAA,
		
		src_network => "dE:fF:0:1",
		src_node    => "Cd:ef:1:23:45:67",
		src_socket  => 0xAAAA,
		
		data => "\x00some \n\xFFdata",
	);
	
	isa_ok($ipx, "NetPacket::IPX");
	
	is($ipx->encode(), $packet, "NetPacket::IPX->encode() encodes the packet correctly");
}

is(NetPacket::IPX::strip($packet), "\x00some \n\xFFdata", "NetPacket::IPX::strip() extracts the packet payload");
