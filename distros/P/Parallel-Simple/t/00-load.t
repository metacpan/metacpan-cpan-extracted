#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parallel::Simple' );
}

diag( "Testing Parallel::Simple $Parallel::Simple::VERSION, Perl $], $^X" );
