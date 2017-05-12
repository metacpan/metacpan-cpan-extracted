#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 5;

use Sort::Key::Radix qw(usort);

for my $range (0xf, 0xaf, 0xaffff, 0xffffff, 0xffffffff) {
    my @d = map { int($range * rand) } 0..200;
    my @good = sort { $a <=> $b } @d;

    my @s = usort @d;

    is("@s", "@good");

}
