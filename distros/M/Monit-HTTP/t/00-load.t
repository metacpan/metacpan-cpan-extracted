#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Monit::HTTP' );
}

diag( "Testing Monit::HTTP $Monit::HTTP::VERSION, Perl $], $^X" );
