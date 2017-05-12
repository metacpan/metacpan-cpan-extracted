#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Log::More' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Log::More $Mojo::Log::More::VERSION, Perl $], $^X" );
