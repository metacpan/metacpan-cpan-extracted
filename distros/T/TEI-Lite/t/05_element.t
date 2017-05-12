# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl inheritance.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok( 'TEI::Lite' ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $element = tei_div( { id => "test" } );

ok( $element );

ok( $element->setLang( "en" ) );

my $lang = $element->getAttribute( "lang" );

ok( $lang eq "en" );

ok( $element->appendChild( tei_p() ) );
