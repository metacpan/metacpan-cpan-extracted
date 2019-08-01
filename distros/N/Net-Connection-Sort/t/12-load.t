#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::port_f' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::port_f $Net::Connection::Sort::port_f::VERSION, Perl $], $^X" );
