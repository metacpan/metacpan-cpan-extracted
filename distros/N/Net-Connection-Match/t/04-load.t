#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::Ports' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::Ports $Net::Connection::Match::Ports::VERSION, Perl $], $^X" );
