#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Monitoring::Sneck::Boop_Snoot' ) || print "Bail out!\n";
}

diag( "Testing Monitoring::Sneck::Boop_Snoot $Monitoring::Sneck::Boop_Snoot::VERSION, Perl $], $^X" );
