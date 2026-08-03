#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Reverse::Proxy' ) || print "Bail out!\n";
}

diag( "Testing Reverse::Proxy $Reverse::Proxy::VERSION, Perl $], $^X" );
