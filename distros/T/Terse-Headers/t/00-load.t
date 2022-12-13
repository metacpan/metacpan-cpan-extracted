#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Terse::Headers' ) || print "Bail out!\n";
}

diag( "Testing Terse::Headers $Terse::Headers::VERSION, Perl $], $^X" );
