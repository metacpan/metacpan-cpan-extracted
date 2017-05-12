#!perl -T
use 5.008_005;
use strict;
no warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Perl::Police' ) || print "Bail out!\n";
}

diag( "Testing Perl::Police $Perl::Police::VERSION, Perl $], $^X" );
