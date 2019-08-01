#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::user' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::user $Net::Connection::Sort::user::VERSION, Perl $], $^X" );
