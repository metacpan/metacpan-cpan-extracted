#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw(time);
use Sort::strverscmp;

use feature ':5.10';

use constant I => 1_000_000;
use constant J => 10;
use constant L => 50;

my $time;
for (my $i = 0; $i < I; $i++) {
    my ($a, $b) = (random_string(L), random_string(L));

    for (my $j = 0; $j < J; $j++) {
        my $start = time();
        my $s1 = strverscmp($a, $b);
        $time += time() - $start;
    }
}

printf("    n = %d\n", (I * J));
printf("    l = %d\n", L);
printf("total = %f\n", $time);
printf(" unit = %f\n", ($time / (I * J)));

sub random_string {
    my $length = shift;
    state $chars = ['a'..'z', 'A'..'Z', '0'..'9', '_', '-', '.', ' '];
    state $nchars = 66;
    return join('', $chars->[rand ($nchars - 1)], map { $chars->[rand $nchars] } (1..$length));
}
