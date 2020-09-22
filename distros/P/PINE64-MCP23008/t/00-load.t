#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PINE64::MCP23008' ) || print "Bail out!\n";
}

diag( "Testing PINE64::MCP23008 $PINE64::MCP23008::VERSION, Perl $], $^X" );
