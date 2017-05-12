#!/usr/bin/env perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Perl::PrereqInstaller' ) || print "Bail out!\n";
}

diag( "Testing Perl::PrereqInstaller $Perl::PrereqInstaller::VERSION, Perl $], $^X" );
