#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Parse::Netstat::Search' ) || print "Bail out!\n";
}

diag( "Testing Parse::Netstat::Search $Parse::Netstat::Search::VERSION, Perl $], $^X" );
