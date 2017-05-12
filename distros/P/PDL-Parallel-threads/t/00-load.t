#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'PDL::Parallel::threads' )
		or BAIL_OUT('Unable to load PDL::Parallel::threads!');
}

diag( "Testing PDL::Parallel::threads $PDL::Parallel::threads::VERSION, Perl $], $^X" );
