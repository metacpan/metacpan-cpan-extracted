#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Nefarious' ) || print "Bail out!\n";
}

diag( "Testing Nefarious $Nefarious::VERSION, Perl $], $^X" );
