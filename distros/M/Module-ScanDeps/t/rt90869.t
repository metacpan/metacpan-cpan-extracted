#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Module::ScanDeps qw(scan_deps);
use lib qw(t/data/static);

my @expected_modules = qw( TestA TestB TestC );
plan tests => scalar @expected_modules;

my $rv = scan_deps("t/data/rt90869.pl");
foreach (@expected_modules)
{
    ok(exists $rv->{"$_.pm"}, "expected module $_ found");
}
