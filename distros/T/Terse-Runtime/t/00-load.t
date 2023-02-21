#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Terse::Runtime' ) || print "Bail out!\n";
}

diag( "Testing Terse::Runtime $Terse::Runtime::VERSION, Perl $], $^X" );
