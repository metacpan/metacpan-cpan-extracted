#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'String::Compile::Tr' ) || print "Bail out!\n";
}

diag( "Testing String::Compile::Tr $String::Compile::Tr::VERSION, Perl $], $^X" );
