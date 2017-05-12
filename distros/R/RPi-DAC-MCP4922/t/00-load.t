#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::DAC::MCP4922' ) || print "Bail out!\n";
}

diag( "Testing RPi::DAC::MCP4922 $RPi::DAC::MCP4922::VERSION, Perl $], $^X" );
