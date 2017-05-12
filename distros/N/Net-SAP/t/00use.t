use strict;
use Test::More tests => 3;


# Check that the module loads ok
BEGIN { use_ok( 'Net::SAP' ); }


# Now try creating a new Net::SAP object
my $sap = new Net::SAP('ipv4');
ok( $sap, "Creating Net::SAP object" );


# Close the socket
$sap->close();
pass( "Closing socket" );
