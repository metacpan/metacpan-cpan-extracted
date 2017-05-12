#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Moonshine::Element' ) || print "Bail out!\n";
}

diag( "Testing Moonshine::Element $Moonshine::Element::VERSION, Perl $], $^X" );
