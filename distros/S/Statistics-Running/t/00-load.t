#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::Running' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Running $Statistics::Running::VERSION, Perl $], $^X" );
