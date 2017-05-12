use strict;
use Test;


# use a BEGIN block so we print our plan before modules are loaded
BEGIN { plan tests => 11 }

# load modules
use Net::LibLO;

# Create objects
my $lo = new Net::LibLO();
ok( $lo );
my $addr = new Net::LibLO::Address( 'localhost', 4542 );
ok( $addr );
my $mesg = new Net::LibLO::Message( 's', 'Hello World' );
ok( $mesg );


# Check port
ok( $lo->get_port() =~ /^\d{4,}$/ );

# Check URL
ok( $lo->get_url() =~ /^osc\.udp\:\/\// );


# Send Message
my $result = $lo->send( $addr, '/foo', $mesg );
ok( $result, 24 );

# Send Bundle
my $bundle = new Net::LibLO::Bundle();
ok( $bundle );
$bundle->add_message( '/bar', $mesg );
$result = $lo->send( $addr, $bundle );
ok( $result, 44 );

# Send Message to localhost port 4538
$result = $lo->send( 4538, '/foo', $mesg );
ok( $result, 24 );

# Send Message to localhost port 4564
$result = $lo->send( 'osc.udp://localhost:4564/', '/foo', $mesg );
ok( $result, 24 );


# Destroy the LibLO object
undef $lo;
ok( 1 );

exit;
