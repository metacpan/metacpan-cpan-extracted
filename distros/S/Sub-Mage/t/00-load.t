#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sub::Mage' ) || print "Bail out!\n";
}

diag( "Testing Sub::Mage $Sub::Mage::VERSION, Perl $], $^X" );
