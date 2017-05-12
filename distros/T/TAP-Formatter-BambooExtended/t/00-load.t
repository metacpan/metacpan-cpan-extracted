#!/usr/bin/perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    # this implicitly tests TAP::Formatter::BambooExtended::Session
    use_ok( 'TAP::Formatter::BambooExtended' ) || print "Bail out!\n";
}

