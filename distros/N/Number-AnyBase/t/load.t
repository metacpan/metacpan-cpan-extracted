#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Number::AnyBase' ) || print "Bail out!\n";
}

diag( "Testing Number::AnyBase $Number::AnyBase::VERSION, Perl $], $^X" );
