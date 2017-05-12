#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Piddy' ) || print "Bail out!\n";
}

diag( "Testing Piddy $Piddy::VERSION, Perl $], $^X" );
