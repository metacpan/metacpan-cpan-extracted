#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Ascii' ) || print "Bail out!\n";

}

diag( "Testing Ascii $Ascii::VERSION, Perl $], $^X" );
