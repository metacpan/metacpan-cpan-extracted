#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Monitoring::Sneck' ) || print "Bail out!\n";
    use_ok( 'Monitoring::Sneck::Config' ) || print "Bail out!\n";
}

diag( "Testing Monitoring::Sneck $Monitoring::Sneck::VERSION, Perl $], $^X" );
