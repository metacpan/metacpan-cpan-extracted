#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Print::Format' ) || print "Bail out!\n";
}

diag( "Testing Print::Format $Print::Format::VERSION, Perl $], $^X" );
