#!perl
use 5.34.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Museum::MetropolitanMuseumArt' ) || print "Bail out!\n";
}

diag( "Testing Museum::MetropolitanMuseumArt $Museum::MetropolitanMuseumArt::VERSION, Perl $], $^X" );
