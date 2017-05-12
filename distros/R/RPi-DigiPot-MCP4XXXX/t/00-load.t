#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::DigiPot::MCP4XXXX' ) || print "Bail out!\n";
}

diag( "Testing RPi::DigiPot::MCP4XXXX $RPi::DigiPot::MCP4XXXX::VERSION, Perl $], $^X" );
