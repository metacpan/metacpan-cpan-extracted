#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Params::Validate::Checks::Net' );
}

diag( "Testing Params::Validate::Checks::Net $Params::Validate::Checks::Net::VERSION, Perl $], $^X" );
