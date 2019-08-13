#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::PctMem' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::PctMem $Net::Connection::Match::PctMem::VERSION, Perl $], $^X" );
