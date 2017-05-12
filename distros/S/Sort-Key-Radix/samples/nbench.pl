#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(cmpthese);

use Sort::Key::Radix;
use Sort::Key;

my @data = map { -5e49 + 1e50 * rand } 0..2_000_000;

cmpthese -1, { builtin => sub { my @s = sort { $a <=> $b } @data },
               sk => sub { my @s = Sort::Key::nsort @data },
               radix => sub { my @s = Sort::Key::Radix::nsort @data }
             };

