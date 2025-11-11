#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Podlite' ) || print "Bail out!\n";
}

diag( "Testing Podlite $Podlite::VERSION, Perl $], $^X" );
