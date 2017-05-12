#!/usr/bin/perl

use strict;
use Test;
use Data::Dumper;

# use a BEGIN block so we print our plan before Net::RTP is loaded
BEGIN { plan tests => 5 }

# load Net::RTP
use Net::RTP;
ok(1);


# Create a packet to send
my $packet = new Net::RTP::Packet();
ok( $packet->payload_type(96) );
ok( $packet->payload('Hello World!') );

# Create a RTP socket and send to localhost
my $rtp = new Net::RTP( PeerAddr=>'127.0.0.1', PeerPort=>5004, Domain=>AF_INET );
ok( defined $rtp );

# Send the packet (returns length of packet sent)
my $result = $rtp->send($packet);
ok( $result == 24 );
