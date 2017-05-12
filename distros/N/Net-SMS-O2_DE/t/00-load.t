#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::SMS::O2_DE' ) || print "Bail out!\n";
}

diag( "Testing Net::SMS::O2_DE $Net::SMS::O2_DE::VERSION, Perl $], $^X" );
