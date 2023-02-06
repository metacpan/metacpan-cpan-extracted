#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Terse::Es' ) || print "Bail out!\n";
}

diag( "Testing Terse::Es $Terse::Es::VERSION, Perl $], $^X" );
