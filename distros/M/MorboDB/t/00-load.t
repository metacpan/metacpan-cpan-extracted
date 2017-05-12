#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MorboDB' ) || print "Bail out!\n";
}

diag( "Testing MorboDB $MorboDB::VERSION, Perl $], $^X" );
