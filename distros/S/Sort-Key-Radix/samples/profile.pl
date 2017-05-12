#!/usr/bin/perl

use strict;
use warnings;

use Sort::Key::Radix qw(usort);

my @data = map { int(50000 * rand) } 0..1_000_000;

my @s = usort @data;


