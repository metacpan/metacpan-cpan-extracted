#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Schedule::Poll' ) || print "Bail out!\n";
}

diag( "Testing Schedule::Poll $Schedule::Poll::VERSION, Perl $], $^X" );
