##
## Test creating and sending a SAP packet
##

use strict;
use Test::More tests => 8;


# Check that the module loads ok
BEGIN { use_ok( 'Net::SAP' ); }


# Create a new Net::SAP object
my $sap = new Net::SAP( 'ipv4' );
ok( defined $sap, "Creating Net::SAP object" );

# Set a low TTL for this test packet
is( $sap->ttl( 1 ), 1, "Set TTL for transmitted packets" );


# Create a new packet to send
my $pkt = new Net::SAP::Packet();
ok( defined $pkt->payload_type('text/plain'), "Setting payload type" );
ok( defined $pkt->payload('Hello World!'), "Setting payload" );

# Very naughty but ok for this test script
ok( defined $pkt->origin_address('127.0.0.1'), "Setting origin address" );
ok( defined $pkt->origin_address_type('ipv4'), "Setting origin address type" );


# Now try and send the packet
ok( defined $sap->send( $pkt ), "Send SAP packet" );
