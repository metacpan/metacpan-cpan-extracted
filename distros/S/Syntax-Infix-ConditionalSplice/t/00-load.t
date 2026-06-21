#!perl
use 5.038;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Syntax::Infix::ConditionalSplice' ) || print "Bail out!\n";
}

diag( "Testing Syntax::Infix::ConditionalSplice $Syntax::Infix::ConditionalSplice::VERSION, Perl $], $^X" );
