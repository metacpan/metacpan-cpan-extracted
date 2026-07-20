#!/usr/bin/perl
# 001_module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
    Sys::OsRelease
);
plan tests => scalar @classes;

foreach my $class (@classes) {
        require_ok($class);
}

1;

