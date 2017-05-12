#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Nginx::Log::Entry' ) || print "Bail out!\n";
}

diag( "Testing Nginx::Log::Entry $Nginx::Log::Entry::VERSION, Perl $], $^X" );
