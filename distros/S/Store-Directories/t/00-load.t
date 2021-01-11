#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Store::Directories' ) || print "Bail out!\n";
}

diag( "Testing Store::Directories $Store::Directories::VERSION, Perl $], $^X" );
