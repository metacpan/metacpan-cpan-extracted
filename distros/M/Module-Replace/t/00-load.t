#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Module::Replace' );
}

diag( "Testing Module::Replace $Module::Replace::VERSION, Perl $], $^X" );
