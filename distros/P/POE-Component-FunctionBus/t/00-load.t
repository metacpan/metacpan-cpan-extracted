#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'POE::Component::FunctionBus' ) || print "Bail out!\n";
}

diag( "Testing POE::Component::FunctionBus $POE::Component::FunctionBus::VERSION, Perl $], $^X" );
