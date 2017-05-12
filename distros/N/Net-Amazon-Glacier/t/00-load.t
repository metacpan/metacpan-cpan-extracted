#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Amazon::Glacier' ) || print "Bail out!\n";
}

diag( "Testing Net::Amazon::Glacier $Net::Amazon::Glacier::VERSION, Perl $], $^X" );
