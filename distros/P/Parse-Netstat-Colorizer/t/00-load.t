#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Parse::Netstat::Colorizer' ) || print "Bail out!\n";
}

diag( "Testing Parse::Netstat::Colorizer $Parse::Netstat::Colorizer::VERSION, Perl $], $^X" );
