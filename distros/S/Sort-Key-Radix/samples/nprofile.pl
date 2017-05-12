#!/usr/bin/perl

use strict;
use warnings;

use Sort::Key::Radix qw(nsort);

my @data = map { 50000 * rand } 0..500_000;

my @s = nsort @data;


