#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.04';

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::Running::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Running::Tiny $Statistics::Running::Tiny::VERSION, Perl $], $^X" );
