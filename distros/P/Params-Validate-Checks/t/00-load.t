#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Params::Validate::Checks' );
}

diag( "Testing Params::Validate::Checks $Params::Validate::Checks::VERSION, Perl $], $^X" );
