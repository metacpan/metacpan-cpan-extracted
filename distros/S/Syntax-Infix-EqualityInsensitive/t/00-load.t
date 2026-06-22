#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    require_ok('Syntax::Infix::EqualityInsensitive') || print "Bail out!\n";
}

diag( "Testing Syntax::Infix::EqualityInsensitive $Syntax::Infix::EqualityInsensitive::VERSION, Perl $], $^X" );
