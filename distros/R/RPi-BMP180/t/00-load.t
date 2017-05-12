#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::BMP180' ) || print "Bail out!\n";
}

diag( "Testing RPi::BMP180 $RPi::BMP180::VERSION, Perl $], $^X" );
