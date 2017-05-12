#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parallel::Mpich::MPD' );
}

diag( "Testing Parallel::Mpich::MPD $Parallel::Mpich::MPD::VERSION, Perl $], $^X" );


