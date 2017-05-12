#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Package::Builder' );
}

diag( "Testing Package::Builder $Package::Builder::VERSION, Perl $], $^X" );
