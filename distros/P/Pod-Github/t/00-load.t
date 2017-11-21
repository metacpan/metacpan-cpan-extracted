#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Pod::Github' ) || print "Bail out!\n";
}

diag( "Testing Pod::Github $Pod::Github::VERSION, Perl $], $^X" );
