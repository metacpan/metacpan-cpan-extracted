#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Month::Simple' ) || print "Bail out!\n";
}

diag( "Testing Month::Simple $Month::Simple::VERSION, Perl $], $^X" );
