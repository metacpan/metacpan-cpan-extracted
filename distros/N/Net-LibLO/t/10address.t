
use strict;
use Test;


# use a BEGIN block so we print our plan before Net::LibLO::Address is loaded
BEGIN { plan tests => 10 }

# load Net::LibLO::Address
use Net::LibLO::Address;

# Create a message object
my $addr = new Net::LibLO::Address( 'localhost', 4542 );
ok( $addr );

# Check get_hostname
ok($addr->get_hostname(), 'localhost');

# Check get_port
ok($addr->get_port(), 4542);

# Check get_url
ok($addr->get_url(), 'osc.udp://localhost:4542/');

# Delete the address object
undef $addr;
ok(1);


# Create a new address object from a URL
$addr = new Net::LibLO::Address( 'osc.tcp://example.net:1234/' );
ok( $addr );

# Check for error number
# (there shouldn't have been one)
ok($addr->errno(), 0);

# Check get_hostname
ok($addr->get_hostname(), 'example.net');

# Check get_port
ok($addr->get_port(), '1234');


# Delete the address object
undef $addr;
ok(1);


exit;
