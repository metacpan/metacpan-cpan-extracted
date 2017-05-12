#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parallel::MPM::Prefork' ) || print "Bail out!\n";
}

diag( "Testing Parallel::MPM::Prefork $Parallel::MPM::Prefork::VERSION, Perl $], $^X" );
