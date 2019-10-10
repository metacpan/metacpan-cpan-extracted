#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::CIDR::Overlap' ) || print "Bail out!\n";
}

diag( "Testing Net::CIDR::Overlap $Net::CIDR::Overlap::VERSION, Perl $], $^X" );
