#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mustache::Simple' ) || print "Bail out!\n";
}

diag( "Testing Mustache::Simple $Mustache::Simple::VERSION, Perl $], $^X" );
