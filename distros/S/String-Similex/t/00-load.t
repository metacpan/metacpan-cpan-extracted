#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'String::Similex' )            || print "Bail out!\n";
}

diag( "Testing String $String::Similex::VERSION, Perl $], $^X" );
