#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Netconf' ) || print "Bail out!\n";
}

diag( "Testing Netconf $Netconf::VERSION, Perl $], $^X" );
