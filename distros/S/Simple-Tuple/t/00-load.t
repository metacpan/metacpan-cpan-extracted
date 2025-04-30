#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Simple::Tuple' ) || print "Bail out!\n";
}

diag( "Testing Simple::Tuple $Simple::Tuple::VERSION, Perl $], $^X" );
