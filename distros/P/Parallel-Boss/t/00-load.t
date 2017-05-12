#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parallel::Boss' ) || print "Bail out!\n";
}

diag( "Testing Parallel::Boss $Parallel::Boss::VERSION, Perl $], $^X" );
