#!/usr/bin/perl
use warnings;
use strict;

use FindBin;
use Test::More tests => 3;

my %counts;
for my $file ("$FindBin::Bin/completness.t",
              "$FindBin::Bin/../t/05-functions.t"
    ) {
    open my $in, '<', $file or fail "$file not found";
    while (<$in>) {
        if (/%count = / .. /}/) {
            while (/(\w+) +=> (\d+)/g) {
                my ($counted, $number) = ($1, $2);
                if (exists $counts{$counted}) {
                    is $counts{$counted}, $number, "same $counted";
                } else {
                    $counts{$counted} = $number;
                }
            }
        }
    }
}
