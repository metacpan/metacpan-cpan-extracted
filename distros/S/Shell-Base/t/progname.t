#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use File::Basename qw(basename);
use Test::More;
use Shell::Base;

my $sh = Shell::Base->new;
my @tests = qw(supershell foo/bar baz.pl quux-baby);

plan tests => scalar @tests + 1;

use_ok("Shell::Base");

for my $test (@tests) {
    $0 = $test;
    is(basename($0), $sh->progname, sprintf "progname ok: %s => %s", $test, basename($0));
}
