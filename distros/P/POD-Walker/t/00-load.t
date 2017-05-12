#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POD::Walker' );
}

diag( "Testing POD::Walker $POD::Walker::VERSION, Perl $], $^X" );
