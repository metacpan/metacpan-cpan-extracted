#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pod::Sub::Usage' ) || print "Bail out!\n";
}

diag( "Testing Pod::Sub::Usage $Pod::Sub::Usage::VERSION, Perl $], $^X" );