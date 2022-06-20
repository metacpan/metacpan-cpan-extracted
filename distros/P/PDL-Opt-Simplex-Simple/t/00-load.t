#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PDL::Opt::Simplex::Simple' ) || print "Bail out!\n";
}

diag( "Testing PDL::Opt::Simplex::Simple $PDL::Opt::Simplex::Simple::VERSION, Perl $], $^X" );
