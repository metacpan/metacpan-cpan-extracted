#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Krippendorff;

use List::Util qw{ sum };

use Test2::V0;
plan 21;

my $sk = 'Statistics::Krippendorff'->new(units => []);

is $sk->delta_nominal('a', 'a'), 0, 'nominal a-a';
is $sk->delta_nominal('a', 'b'), 1, 'nominal a-b';

is $sk->delta_jaccard('a', 'a'), 0, 'a a';
is $sk->delta_jaccard('a', 'b'), 1, 'a b';

is $sk->delta_jaccard('a', 'a,b'), 0.5, 'a ab';
is $sk->delta_jaccard('a', 'b,a'), 0.5, 'a ba';
is $sk->delta_jaccard('a,b', 'a'), 0.5, 'ab a';
is $sk->delta_jaccard('b,a', 'a'), 0.5, 'ba a';

is $sk->delta_jaccard('a,b', 'c,d'), 1, 'ab cd';
is $sk->delta_jaccard('a,b', 'a,b'), 0, 'ab ab';
is $sk->delta_jaccard('a,b', 'b,a'), 0, 'ab ba';
is $sk->delta_jaccard('a,b', 'a,c'), 2/3, 'ab ac';
is $sk->delta_jaccard('a,b', 'c,a'), 2/3, 'ab ca';
is $sk->delta_jaccard('b,a', 'c,a'), 2/3, 'ba ca';
is $sk->delta_jaccard('b,a', 'a,c'), 2/3, 'ba ac';

is $sk->delta_jaccard('a,b,c', 'b,c,d,e'), 3/5, 'abc bcde';

is $sk->delta_masi('1,2', '1,2,3,4'), 2/3, 'masi';

# Passonneau 2006
# Note that the results are different than stated in the article, I fixed
# errors found in the article, results confirmed by Passonneau via e-mail.
my @figures = (
    [['x,y', 'x,y,z'], ['x,y', 'x,y,z'], ['z', 'x,y,z']],
    [['x,y', 'x'], ['x,y', 'y,z'], ['z', 'y,z']]
);

my %means = (jaccard => [4 / 9, 5 / 9],
             masi    => [2 / 9, 0]);
for my $figure_index (0 .. $#figures) {
    my $figure = $figures[$figure_index];
    my $figure_number = 2 + $figure_index;
    my @jaccard_deltas = map $sk->delta_jaccard(@$_), @$figure;
    my $j_mean = sum(@jaccard_deltas) / @jaccard_deltas;
    is $j_mean, shift @{ $means{jaccard} }, "fig$figure_number jaccard mean";

    if (0 == $figure_index) {
        $figure = [['y', 'y,z'], ['x', 'x,z'], ['','x,y']];
    } else {
        $figure = [['y', ''], ['x', 'z'], ['', 'y']];
    }

    my @masi_deltas = map $sk->delta_masi(@$_), @$figure;
    my $m_mean = 1 - sum(@masi_deltas) / @masi_deltas;
    is $m_mean, shift @{ $means{masi} }, "fig$figure_number masi mean";
}
