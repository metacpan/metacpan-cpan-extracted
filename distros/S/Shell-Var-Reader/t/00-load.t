#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Shell::Var::Reader' ) || print "Bail out!\n";
}

diag( "Testing Shell::Var::Reader $Shell::Var::Reader::VERSION, Perl $], $^X" );
