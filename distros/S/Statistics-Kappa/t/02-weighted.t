#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Kappa::Weighted;

use Test::More tests => 2;

subtest 'numiqo' => sub {
    plan(tests => 1);
    my @data = (([1, 1]) x 17, ([1, 2]) x  8, ([1, 3]) x 4,
                ([2, 1]) x  6, ([2, 2]) x 19, ([2, 3]) x 3,
                ([3, 1]) x  3, ([3, 2]) x  6, ([3, 3]) x 9);

    my $wk = 'Statistics::Kappa::Weighted'->new(data   => \@data,
                                                weight => 'linear');

    is sprintf('%.3f', $wk->kappa), 0.396, 'linear';
};

subtest 'spssfocus' => sub {
    plan(tests => 4);
    my @data = ([1, 1, 1], [1, 1, 3], [2, 1, 1], [1, 1, 1], [3, 2, 3],
                [3, 3, 2], [2, 2, 2], [1, 1, 1], [2, 2, 2], [3, 3, 3],
                [1, 1, 1], [1, 1, 1], [2, 2, 1], [1, 2, 1], [2, 1, 2],
                [3, 2, 2], [3, 3, 3], [2, 2, 3], [1, 1, 1], [1, 2, 1],
                [3, 3, 1], [1, 1, 1], [1, 1, 3], [1, 1, 2], [1, 1, 1]);

    my $wk1 = 'Statistics::Kappa::Weighted'->new(
        data => [map [@$_[0, 1]], @data],
        weight => sub { $_[0] != $_[1] });
    is sprintf('%.3f', $wk1->kappa), 0.609, 'no weighting candidate 1';

    my $wk2 = 'Statistics::Kappa::Weighted'->new(
        data => [map [@$_[0, 2]], @data],
        weight => sub { $_[0] != $_[1] });
    is sprintf('%.3f', $wk2->kappa), 0.414, 'no weighting candidate 2';

    my $wk3 = 'Statistics::Kappa::Weighted'->new(
        data => [map [@$_[0, 1]], @data],
        weight => 'quadratic');
    is sprintf('%.3f', $wk3->kappa), 0.806, 'quadratic candidate 1';

    my $wk4 = 'Statistics::Kappa::Weighted'->new(
        data => [map [@$_[0, 2]], @data],
        weight => 'quadratic');
    is sprintf('%.3f', $wk4->kappa), 0.472, 'quadratic candidate 2';
}
