#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Match::Protos' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Match::Protos $Net::Connection::Match::Protos::VERSION, Perl $], $^X" );
