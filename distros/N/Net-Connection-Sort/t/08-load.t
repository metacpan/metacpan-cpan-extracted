#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::pid' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::pid $Net::Connection::Sort::pid::VERSION, Perl $], $^X" );
