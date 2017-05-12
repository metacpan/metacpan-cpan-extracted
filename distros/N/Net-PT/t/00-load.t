#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::PT' ) || print "Bail out!\n";
}

diag( "Testing Net::PT $Net::PT::VERSION, Perl $], $^X" );
