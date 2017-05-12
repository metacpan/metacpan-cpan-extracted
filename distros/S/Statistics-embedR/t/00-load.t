#!perl -T

use Test::More tests => 1;

BEGIN { use_ok( 'Statistics::embedR' ) || print "Bail out!\n" }

diag( "Testing Statistics::embedR $Statistics::embedR::VERSION, Perl $], $^X" );
