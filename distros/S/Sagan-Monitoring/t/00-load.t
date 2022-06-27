#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Sagan::Monitoring' ) || print "Bail out!\n";
}

diag( "Testing Sagan::Monitoring $Sagan::Monitoring::VERSION, Perl $], $^X" );
