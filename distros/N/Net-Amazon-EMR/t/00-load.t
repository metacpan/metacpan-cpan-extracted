#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Amazon::EMR' ) || print "Bail out!\n";
}

diag( "Testing Net::Amazon::EMR $Net::Amazon::EMR::VERSION, Perl $], $^X" );
