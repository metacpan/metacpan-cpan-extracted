#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Reddit' ) || print "Bail out!\n";
}

diag( "Testing Reddit $Reddit::VERSION, Perl $], $^X" );
