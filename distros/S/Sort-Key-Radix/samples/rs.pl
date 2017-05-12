#!/usr/bin/perl

use warnings;
use strict;

use Scalar::Quote 'D';

use Sort::Key::Radix qw(usort);

my @d = map { int(450 * rand) } 0..200;

my @s = usort @d;
my @good = sort { $a <=> $b } @d;

print "\n@d\nsorted:\n@s\nexpected:\n@good\n";

D("@s", "@good") and print "rs: $a\ngd: $b\n\n";

