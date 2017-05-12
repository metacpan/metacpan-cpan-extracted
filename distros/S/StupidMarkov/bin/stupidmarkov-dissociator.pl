#!/usr/bin/perl

use strict;
use warnings;

use StupidMarkov;

my $mm = StupidMarkov->new();

while (my $line = <>) {
    chomp($line);
    next if (!defined($line));

    foreach my $word (split(/ /, $line)) {
        $mm->add_item($word);
    }
}


print $mm->get_next_item(), " " for (0 .. $mm->get_item_count());
