#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Struct::Conditional' ) || print "Bail out!\n";
}

diag( "Testing Struct::Conditional $Struct::Conditional::VERSION, Perl $], $^X" );
