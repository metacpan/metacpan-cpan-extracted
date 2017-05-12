#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Set::Groups' );
}

diag( "Testing Set::Groups $Set::Groups::VERSION, Perl $], $^X" );
