#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::Username' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::Username $Net::Connection::Match::Username::VERSION, Perl $], $^X" );
