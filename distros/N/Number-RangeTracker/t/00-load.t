#!/usr/bin/env perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Number::RangeTracker' ) || print "Bail out!\n";
}

diag( "Testing Number::RangeTracker $Number::RangeTracker::VERSION, Perl $], $^X" );
