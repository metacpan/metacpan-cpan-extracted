#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Moonshine::Parser' ) || print "Bail out!\n";
}

diag( "Testing Moonshine::Parser $Moonshine::Parser::VERSION, Perl $], $^X" );
