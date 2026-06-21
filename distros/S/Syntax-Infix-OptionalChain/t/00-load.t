#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Syntax::Infix::OptionalChain' ) || print "Bail out!\n";
}

diag( "Testing Syntax::Infix::OptionalChain $Syntax::Infix::OptionalChain::VERSION, Perl $], $^X" );
