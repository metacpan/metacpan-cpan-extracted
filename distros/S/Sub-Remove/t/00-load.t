#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Sub::Remove' ) || print "Bail out!\n";
}

diag( "Testing Sub::Remove $Sub::Remove::VERSION, Perl $], $^X" );
