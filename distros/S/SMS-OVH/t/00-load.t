#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SMS::OVH' ) || print "Bail out!\n";
}

diag( "Testing SMS::OVH $SMS::OVH::VERSION, Perl $], $^X" );
