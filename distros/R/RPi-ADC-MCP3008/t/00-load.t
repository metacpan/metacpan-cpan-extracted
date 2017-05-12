#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::ADC::MCP3008' ) || print "Bail out!\n";
}

diag( "Testing RPi::ADC::MCP3008 $RPi::ADC::MCP3008::VERSION, Perl $], $^X" );
