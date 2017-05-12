#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Set::Toolkit' );
}

diag( "Testing Set::Toolkit $Set::Toolkit::VERSION, Perl $], $^X" );
