#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::PTR' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::PTR $Net::Connection::Match::PTR::VERSION, Perl $], $^X" );
