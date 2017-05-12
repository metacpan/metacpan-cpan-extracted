#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(cmpthese);

use Sort::Key::Radix;
use Sort::Key;

my @l = (-100000 .. 100000);
my $l = "@l";

print "data populated\n";

my @data = map { join('', @l[ map { rand(@l) } 0.. int(4*rand) ]) } 0 .. 100_000;

cmpthese -1, { builtin => sub { my @s = sort @data },
               radix => sub { my @s = Sort::Key::Radix::ssort @data }
             };

