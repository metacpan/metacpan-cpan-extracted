#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Ecrawler' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Ecrawler $Mojo::Ecrawler::VERSION, Perl $], $^X" );
