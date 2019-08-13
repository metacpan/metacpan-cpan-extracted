#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::PID' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::PID $Net::Connection::Match::PID::VERSION, Perl $], $^X" );
