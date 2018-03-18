#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Address::IP::Cipher' ) || print "Bail out!\n";
}

diag( "Testing Net::Address::IP::Cipher $Net::Address::IP::Cipher::VERSION, Perl $], $^X" );
