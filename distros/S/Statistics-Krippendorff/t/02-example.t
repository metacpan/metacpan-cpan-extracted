#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Krippendorff;

use Test2::V0;
use Test2::Tools::Subtest qw{ subtest_buffered };
plan 3;

subtest_buffered wikipedia => sub {
    plan 3;
    my @units_h = ({B=>2, C=>2}, {B=>1, C=>1}, {B=>3, C=>3}, {A=>3, B=>3, C=>4},
                   {A=>4, B=>4, C=>4}, {A=>1, B=>3}, {A=>2, C=>2}, {A=>1, C=>1},
                   {A=>1, C=>1}, {A=>3, C=>3}, {A=>3, C=>3}, {A=>3, C=>4});
    my $sk1 = 'Statistics::Krippendorff'->new(
        units => \@units_h,
        delta => \&Statistics::Krippendorff::delta_nominal);

    is $sk1->alpha, float(0.691, precision => 3),
        'Hash units, default delta';

    my @units_a = ([undef, 2, 2],
                   [undef, 1, 1],
                   [undef, 3, 3],
                   [3, 3, 4],
                   [4, 4, 4],
                   [1, 3],
                   [2, undef, 2],
                   [1, undef, 1],
                   [1, undef, 1],
                   [3, undef, 3],
                   [3, undef, 3],
                   [3, undef, 4]);

    my $sk2 = 'Statistics::Krippendorff'->new(units => \@units_a);
    is $sk2->alpha, float(0.691, precision => 3),
        'Array units, default delta';

    $sk2->delta(\&Statistics::Krippendorff::delta_interval);
    is $sk2->alpha, float(0.811, precision => 3),
        'Array units, interval delta';
};

subtest_buffered krippendorf_1980 => sub {
    plan 4;

    my @units = ([1,1,undef,1],[2,2,3,2],[3,3,3,3],[3,3,3,3],[2,2,2,2],
                 [1,2,3,4],[4,4,4,4],[1,1,2,1],[2,2,2,2],[undef,5,5,5],
                 [undef,undef,1,1]);
    my $sk = 'Statistics::Krippendorff'->new(units => \@units);

    is $sk->alpha, float(0.743, precision => 3),
        'nominal';

    $sk->delta(\&Statistics::Krippendorff::delta_interval);
    is $sk->alpha, float(0.849, precision => 3),
        'interval';

    $sk->delta(\&Statistics::Krippendorff::delta_ordinal);
    is $sk->alpha, float(0.815, precision => 3),
        'ordinal';

    $sk->delta(\&Statistics::Krippendorff::delta_ratio);
    is $sk->alpha, float(0.797, precision => 3),
        'ratio';
};

subtest_buffered stackexchange_stats_511927 => sub {
    plan 2;

    my @units = (['f,s', 'f', 's,e,m'],
                 ['s', 's', 's,e']);
    my $sk = 'Statistics::Krippendorff'->new(
        units => \@units, delta => 'jaccard');
    is $sk->alpha, float(0.152, precision => 3);

    $sk->delta('masi');
    is $sk->alpha, float(0.1296, precision => 4);  # nltk would say 0.1297
};
