#!/usr/bin/perl
# 001_module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
    Sys::OsRelease::Lite
);
plan tests => scalar @classes;

foreach my $class (@classes) {
        require_ok($class);
}

1;


=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

