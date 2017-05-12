#!/usr/bin/perl -I../lib

use Test::More tests => 3;
use Data::Dumper;

BEGIN {
    use_ok( 'PFIX' ) || print "Bail out!\n";
}

diag( "Testing PFIX $PFIX::VERSION, Perl $], $^X" );

use_ok( 'PFIX::Dictionary' ) || print "Bail out!\n";
#use_ok( 'PFix::FIX44' ) || print "Bail out!\n";

ok(PFIX::Dictionary::load('FIX44'), "PFIX::Dictionary::load('FIX44')");
