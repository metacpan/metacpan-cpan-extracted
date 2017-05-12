
use strict;
use Test;


# use a BEGIN block so we print our plan before modules are loaded
BEGIN { plan tests => 4 }

# load Net::LibLO::Bundle and Message
use Net::LibLO::Bundle;
use Net::LibLO::Message;

# Create a new bundle with a time tag
my $bndl= new Net::LibLO::Bundle( 1, 2 );
ok( $bndl );

# Add a new message object
my $msg = new Net::LibLO::Message( 'i', 1287 );
$bndl->add_message( '/bar', $msg );
ok(1);


# Check the length of the message
ok( $bndl->length(), 36 );


## XXX: Check serialize here.


# Delete the bundle
undef $bndl;
ok(1);

exit;

