#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Package::Rename' );
}

diag( "Testing Package::Rename $Package::Rename::VERSION, Perl $], $^X" );
