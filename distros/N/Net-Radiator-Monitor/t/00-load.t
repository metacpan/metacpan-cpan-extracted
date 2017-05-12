#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Radiator::Monitor' ) || print "Bail out!\n";
}

diag( "Testing Net::Radiator::Monitor $Net::Radiator::Monitor::VERSION, Perl $], $^X" );
