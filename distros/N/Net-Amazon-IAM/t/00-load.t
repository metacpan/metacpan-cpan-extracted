#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Amazon::IAM' ) || print "Bail out!\n";
}

diag( "Testing Net::Amazon::IAM $Net::Amazon::IAM::VERSION, Perl $], $^X" );
