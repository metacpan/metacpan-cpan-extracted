#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    require_ok( 'String::Any::Extensions' ) || print "Bail out!\n";
}

diag( "Testing String::Any::Extensions $String::Any::Extensions::VERSION, Perl $], $^X" );
