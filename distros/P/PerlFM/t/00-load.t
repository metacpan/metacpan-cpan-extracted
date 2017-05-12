#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PerlFM' );
}

diag( "Testing PerlFM $PerlFM::VERSION, Perl $], $^X" );
