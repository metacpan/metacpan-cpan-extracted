#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::proto' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::proto $Net::Connection::Sort::proto::VERSION, Perl $], $^X" );
