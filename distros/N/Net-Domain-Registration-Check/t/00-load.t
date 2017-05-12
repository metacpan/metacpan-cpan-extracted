#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Domain::Registration::Check' ) || print "Bail out!\n";
}

diag( "Testing Net::Domain::Registration::Check $Net::Domain::Registration::Check::VERSION, Perl $], $^X" );
