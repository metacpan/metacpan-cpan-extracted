#!/usr/bin/perl -I../lib

use Test::More tests => 3;

BEGIN {
    use_ok( 'PFIX' ) || print "Bail out!";
}

diag( "Testing PFIX $PFIX::VERSION, Perl $], $^X" );
use_ok( 'PFIX::Dictionary' ) || print "Bail out!";
use_ok( 'PFIX::Message' ) || print "Bail out!";
