#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Amazon::Signature::V4' ) || print "Bail out!\n";
}

diag( "Testing Net::Amazon::Signature::V4 $Net::Amazon::Signature::V4::VERSION, Perl $], $^X" );
