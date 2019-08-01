#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Connection::Sort::state' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::state $Net::Connection::Sort::state::VERSION, Perl $], $^X" );
