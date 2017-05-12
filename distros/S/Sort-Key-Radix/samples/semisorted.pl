#!/usr/bin/perl

use strict;
use warnings;

$| = 1;

use Benchmark qw(cmpthese);

use Sort::Key::Radix;
use Sort::Key;

my @data = map { int(500000 * rand) } 0..20_000;

my @ss = Sort::Key::Radix::usort @data;

for (0..int(0.1 * @data)) {
    my $i = int(@data * rand);
    my $j = int(@data * rand);

    next unless $j > $i;

    my $w = int (3*rand);
    if ($w == 0) {
        @ss[$i..$j] = @ss[$j, $i..($j-1)];
    }
    elsif ($w == 1) {
        @ss[$i..$j] = @ss[($i+1)..$j, $i];
    }
    else {
        @ss[$j, $i] = @ss[$i, $j];
    }
}

print "semi sorted data created\n";

cmpthese -1, { builtin => sub { my @s = sort { $a <=> $b } @ss },
               sk => sub { my @s = Sort::Key::usort @ss },
               radix => sub { my @s = Sort::Key::Radix::usort @ss }
             };

