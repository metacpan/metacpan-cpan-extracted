#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OSLV::Monitor' ) || print "Bail out!\n";
}

diag( "Testing OSLV::Monitor $OSLV::Monitor::VERSION, Perl $], $^X" );
