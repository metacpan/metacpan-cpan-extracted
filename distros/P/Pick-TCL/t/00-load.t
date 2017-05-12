#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Pick::TCL' ) || print "Bail out!\n";
}

diag( "Testing Pick::TCL $Pick::TCL::VERSION, Perl $], $^X" );
