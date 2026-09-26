#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Kappa::Fleiss;

use Test::More tests => 1;

{   my @data = ([0, 0, 0, 0, 14],
                [0, 2, 6, 4, 2],
                [0, 0, 3, 5, 6],
                [0, 3, 9, 2, 0],
                [2, 2, 8, 1, 1],
                [7, 7, 0, 0, 0],
                [3, 2, 6, 3, 0],
                [2, 5, 3, 2, 2],
                [6, 5, 2, 1, 0],
                [0, 2, 2, 3, 7]);

    my $fk = 'Statistics::Kappa::Fleiss'->new(data => \@data);
    is sprintf('%.3f', $fk->kappa), '0.210', 'wikipedia';
}

