#!/usr/bin/perl
#
# This example script sends out Hello World packets
# every five seconds to IPv6 Link Local SAP group.
#

use Net::SAP;
use Data::Dumper;
use strict;


# Autoflush STDOUT
$| = 1;


my $sap = new Net::SAP( 'ipv6-link' );
die "Failed to create Net::SAP" unless ($sap);

my $packet = new Net::SAP::Packet();
$packet->payload_type( 'text/plain' );
$packet->payload( 'Hello World!' );
$packet->compressed( 0 );

print Dumper( $packet );


# Send the packet repeatedly
while (1) {
	
	$sap->send( $packet );
	print ".";

	sleep 5;
}

