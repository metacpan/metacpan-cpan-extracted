#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::SPI' ) || print "Bail out!\n";
}

diag( "Testing RPi::SPI $RPi::SPI::VERSION, Perl $], $^X" );
