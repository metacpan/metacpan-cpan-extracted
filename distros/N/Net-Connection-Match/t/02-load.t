#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::States' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::States $Net::Connection::Match::States::VERSION, Perl $], $^X" );
