#!perl
use 5.34.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Museum::TePapa' ) || print "Bail out!\n";
}

diag( "Testing Museum::TePapa $Museum::TePapa::VERSION, Perl $], $^X" );
