#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::CloudStack' ) || print "Bail out!\n";
}

diag( "Testing Net::CloudStack $Net::CloudStack::VERSION, Perl $], $^X" );
