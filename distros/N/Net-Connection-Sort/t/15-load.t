#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::port_la' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::port_la $Net::Connection::Sort::port_la::VERSION, Perl $], $^X" );
