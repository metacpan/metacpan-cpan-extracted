
use strict;
use Test;


# use a BEGIN block so we print our plan before Net::LibLO::Message is loaded
BEGIN { plan tests => 13 }

# load Net::LibLO::Message
use Net::LibLO::Message;

# Create a message object
my $mesg = new Net::LibLO::Message();
ok( $mesg );


## Add lots of different types
$mesg->add_char('a');
ok( 1 );

$mesg->add_nil();
ok( 1 );

$mesg->add_true();
ok( 1 );

$mesg->add_false();
ok( 1 );

$mesg->add_infinitum();
ok( 1 );

$mesg->add_double( 0.5 );
ok( 1 );

$mesg->add_float( 0.5 );
ok( 1 );

$mesg->add_int32( 10 );
ok( 1 );

$mesg->add_string( "test" );
ok( 1 );

$mesg->add_symbol( "test" );
ok( 1 );

# Check that resulting message is the right length
my $length = $mesg->length('/test');
print "# length of message is $length bytes.\n";
ok( $length, 56 );


# XXX: Check serialize here 


# Delete the message
undef $mesg;
ok(1);

exit;

