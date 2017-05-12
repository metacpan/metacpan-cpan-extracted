# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl use.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok( 'TEI::Lite' ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

require_ok( 'TEI::Lite' );
require_ok( 'TEI::Lite::Document' );
require_ok( 'TEI::Lite::Element' );
require_ok( 'TEI::Lite::Header' );
require_ok( 'TEI::Lite::Utility' );
