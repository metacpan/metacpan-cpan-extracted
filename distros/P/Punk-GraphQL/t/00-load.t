#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Punk::GraphQL' ) || print "Bail out!\n";
}

diag( "Testing Punk::GraphQL $Punk::GraphQL::VERSION, Perl $], $^X" );
