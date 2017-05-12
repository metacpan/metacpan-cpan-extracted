#!/usr/bin/perl

use strict;
use Test;
use Data::Dumper;

# use a BEGIN block so we print our plan before Net::RTP::Packet is loaded
BEGIN { plan tests => 27 }

# load Net::RTP::Packet
use Net::RTP::Packet;
ok(1);


# Binary RTP packet
my $binin = pack( 'C*', 
	0xA0, 0xE0, 0xF9, 0x72,
	0x2D, 0x7A, 0xFE, 0x98,		# Timestamp
	0x6E, 0xBB, 0xF8, 0x28,		# SSRC
	0x70, 0x65, 0x72, 0x6C,		# 'perl'
	0x00, 0x00, 0x00, 0x04 		# 4 bytes of padding
);


# Parse the binary packet
my $packet = new Net::RTP::Packet( $binin );
ok( defined $packet );
ok( $packet->version() == 2 );
ok( $packet->padding() == 4 );
ok( $packet->extension() == 0 );
ok( $packet->marker() == 1 );
ok( $packet->payload_type() == 96 );
ok( $packet->seq_num() == 63858 );
ok( $packet->timestamp() == 763035288 );
ok( $packet->ssrc() == 1857812520 );
ok( $packet->payload() eq 'perl' );
ok( $packet->payload_size() == 4 );
ok( $packet->size() == 20 );


# Now create an identical packet
my $packet2 = new Net::RTP::Packet();
ok( $packet2->padding(4) );
ok( $packet2->marker(1) );
ok( $packet2->payload_type(96) );
ok( $packet2->seq_num(63858) );
ok( $packet2->timestamp(763035288) );
ok( $packet2->ssrc(1857812520) );
ok( $packet2->payload('perl') );

# Check that it is the same as the original
my $binout = $packet2->encode();
ok( $binout eq $binin );
ok( $packet2->size() == 20 );



# More packet creation tests
my $packet3 = new Net::RTP::Packet();
ok( $packet3->seq_num() );    # Should be a random number
ok( $packet3->timestamp() );  # Should be a random number
ok( $packet3->ssrc() );       # Should be a random number

# Test incrementing
my $seq_num = $packet3->seq_num();
ok( $packet3->seq_num_increment() == $seq_num+1 );
my $timestamp = $packet3->timestamp();
ok( $packet3->timestamp_increment(10) == $timestamp+10 );


