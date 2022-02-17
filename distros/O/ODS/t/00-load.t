#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ODS' ) || print "Bail out!\n";
}

diag( "Testing ODS $ODS::VERSION, Perl $], $^X" );
