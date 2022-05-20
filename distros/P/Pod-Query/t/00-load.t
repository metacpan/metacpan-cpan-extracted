#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
   use_ok( 'Pod::Query' ) || print "Bail out!\n";
}

diag( "Testing Pod::Query $Pod::Query::VERSION, Perl $], $^X" );
