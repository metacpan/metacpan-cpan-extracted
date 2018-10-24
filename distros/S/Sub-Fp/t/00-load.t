#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Sub::Fp' ) || print "Bail out!\n";
}

diag( "Testing Sub::Fp $Sub::Fp::VERSION, Perl $], $^X" );
