#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;

plan tests => 10;

use Shell::Base qw(shell);

ok(defined $main::{'shell'},
    'Shell::Base->import("shell") creates a pseudo-function');

my @packages = (qw(One Two Three Four Five Six Seven Eight Nine));

# Some gratuitous tests here.
# This is intended to test inherited import methods.
# A series of packages are defined, with a linear ISA hierarchy
# (i.e., each one inherits from the previous one) with Shell::Base
# at the top providing one shared import method.
for (my $i = 0; $i < @packages; $i++) {
    my $pack = $packages[$i];
    my $lastpack = $i == 0 ? "Shell::Base" : $packages[$i - 1];

    my $str = "
    package $pack;
    use base qw($lastpack);";

    eval $str;
}

my $deep = 1;
my $suffix = '';

for (my $i = 0; $i < @packages; $i++) {
    undef $main::{'shell'};

    my $pack = $packages[$i];
    $pack->import('shell');

    Test::More::ok(defined $main::{'shell'},
        "$pack->import('shell') creates a pseudo-function $deep level$suffix deep");

    $deep++;
    $suffix = 's' unless $suffix;
}
