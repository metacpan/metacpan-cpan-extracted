#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mxpress::PDF' ) || print "Bail out!\n";
}

diag( "Testing Mxpress::PDF $Mxpress::PDF::VERSION, Perl $], $^X" );
