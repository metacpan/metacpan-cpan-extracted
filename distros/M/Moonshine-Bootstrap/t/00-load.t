#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Moonshine::Bootstrap::Component' ) || print "Bail out!\n";
}

diag( "Testing Moonshine::Bootstrap $Moonshine::Bootstrap::VERSION, Perl $], $^X" );
