#!/usr/bin/perl
use warnings;
use strict;

use FindBin;
use Test::More;

my @FILES = grep -f "$FindBin::Bin/../$_",
            qw( lib/Syntax/Construct.pm README.pod );

plan(tests => scalar @FILES);

my $current_year = +(localtime)[5] + 1900;
for my $file (@FILES) {
    open my $in, '<', "$FindBin::Bin/../$file" or die "$file: $!";
    while (<$in>) {
        next unless my ($year) = /Copyright(?: \(C\))? 2013 - ([0-9]+)/;

        is($year, $current_year, $file);
    }
}
