#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Mxpress::PDF' );
    use_ok( 'Mxpress::PDF::Mechanize' ) || print "Bail out!\n";
}

diag( "Testing Mxpress::PDF::Mechanize $Mxpress::PDF::Mechanize::VERSION, Perl $], $^X" );
