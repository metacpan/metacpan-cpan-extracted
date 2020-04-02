#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::IPAM::IP' ) || print "Bail out!\n";
}

diag( "Testing Net::IPAM::IP, Perl $], $^X" );
