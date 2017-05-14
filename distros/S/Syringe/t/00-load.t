#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Syringe' ) || print "Bail out!\n";
}

diag( "Testing Syringe $Syringe::VERSION, Perl $], $^X" );
