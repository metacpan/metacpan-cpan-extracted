##
## Tests to check SAP Packet class parsing/generating
##

use strict;
use Test::More tests => 57;


# Check that the module loads ok
BEGIN { use_ok( 'Net::SAP::Packet' ); }


# Create a new Net::SAP::Packet object
my $pkt = new Net::SAP::Packet();
ok( defined $pkt, "Creating Net::SAP::Packet object" );

# Set the origin address type
ok( defined $pkt->origin_address_type('ipv4'), "Setting origin address type" );

# Set the origin address
ok( defined $pkt->origin_address('152.78.64.103'), "Setting origin address" );

# Enable compression
ok( defined $pkt->compressed(1), "Enabling compression" );

# Set packet type to deletion
ok( defined $pkt->type('deletion'), "Setting packet type" );

# Set payload MIME type to 'text/plain'
ok( defined $pkt->payload_type('text/plain'), "Setting payload type" );

# Set payload to 'Hello World'
ok( defined $pkt->payload('Hello World!'), "Setting payload" );





# Binary data that packet to compare with
my @bincheck = (
	0x25, 0x00, 0x0c, 0xd3, 0x98, 0x4e, 0x40, 0x67, 0x78, 0x9c, 0x2b, 
	0x49, 0xad, 0x28, 0xd1, 0x2f, 0xc8, 0x49, 0xcc, 0xcc, 0x63, 0xf0, 
	0x48, 0xcd, 0xc9, 0xc9, 0x57, 0x08, 0xcf, 0x2f, 0xca, 0x49, 0x51, 
	0x04, 0x00, 0x67, 0x1a, 0x08, 0x46, 0x00                    
);


# Compare generated packet with binary data
my $bpkt = $pkt->generate();
for(my $i=0; $i<length($bpkt); $i++) {
	is( ord(substr( $bpkt, $i, 1)), $bincheck[ $i ], "Check binary packet byte" );
}




# Now re-parse the packet
my $pkt2 = new Net::SAP::Packet( $bpkt );
ok( defined $pkt2, "Creating Net::SAP::Packet object" );

# And check all the values we set earlier
is( $pkt2->version(), 1, "Checking packet version" );
is( $pkt2->message_id_hash(), 3283, "Checking packet hash" );
is( $pkt2->origin_address_type(), 'ipv4', "Checking origin address type" );
is( $pkt2->origin_address(), '152.78.64.103', "Checking origin address" );
is( $pkt2->compressed(), 1, "Checking if packet was compressed" );
is( $pkt2->encrypted(), 0, "Checking if packet was encrypted" );
is( $pkt2->type(), 'deletion', "Checking packet type" );
is( $pkt2->payload_type(), 'text/plain', "Checking payload type" );
is( $pkt2->payload(), 'Hello World!', "Checking payload" );

