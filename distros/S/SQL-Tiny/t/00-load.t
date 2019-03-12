#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SQL::Tiny' ) || print "Bail out!\n";
}

diag( "Testing SQL::Tiny $SQL::Tiny::VERSION, Perl $], $^X" );
