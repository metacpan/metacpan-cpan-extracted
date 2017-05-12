#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Params::Validate::Micro' );
}

diag( "Testing Params::Validate::Micro $Params::Validate::Micro::VERSION, Perl $], $^X" );
