#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Log::Che' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Log::Che $Mojo::Log::Che::VERSION, Perl $], $^X" );
