#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Termux::API' ) || print "Bail out!\n";
}

diag( "Testing Termux::API $Termux::API::VERSION, Perl $], $^X" );
