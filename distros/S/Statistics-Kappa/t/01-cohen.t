#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Kappa::Cohen;

use Test::More tests => 6;

subtest 'wikipedia' => sub {
    plan(tests => 1);
    my @answers;
    push @answers, [1, 1] for 1 .. 20;
    push @answers, [0, 0] for 1 .. 15;
    push @answers, [1, 0] for 1 .. 5;
    push @answers, [0, 1] for 1 .. 10;

    my $ck = 'Statistics::Kappa::Cohen'->new(data => \@answers);
    is $ck->kappa, 0.4, 'kappa';
};

subtest 'numiqo.com tutorial' => sub {
    plan(tests => 1);
    my @answers;
    push @answers, ['not depressed', 'not depressed'] for 1 .. 17;
    push @answers, ['depressed', 'depressed'] for 1 .. 19;
    push @answers, ['not depressed', 'depressed'] for 1 .. 8;
    push @answers, ['depressed', 'not depressed'] for 1 .. 6;

    my $ck = 'Statistics::Kappa::Cohen'->new(data => \@answers);
    is sprintf('%.2f', $ck->kappa), 0.44, 'kappa';
};

subtest 'r-project.com' => sub {
    plan(tests => 3);
    my @answers;
    push @answers, [0, 0] for 1 .. 48;
    push @answers, [0, 1] for 1 .. 16;
    push @answers, [1, 0] for 1 .. 12;
    push @answers, [1, 1] for 1 .. 160;

    my $ck = 'Statistics::Kappa::Cohen'->new(data => \@answers);
    is sprintf('%.4f', $ck->observed_agreement), 0.8814, 'observed';
    is sprintf('%.4f', $ck->expected_agreement), 0.6125, 'expected';
    is sprintf('%.4f', $ck->kappa), 0.6938, 'kappa';
};

subtest 'J. Koval uwo.ca' => sub {
    plan(tests => 3);
    my @answers;
    push @answers, ['present', 'present'] for 1 .. 40;
    push @answers, ['absent', 'present'] for 1 .. 15;
    push @answers, ['present', 'absent'] for 1 .. 10;
    push @answers, ['absent', 'absent'] for 1 .. 35;

    my $ck = 'Statistics::Kappa::Cohen'->new(data => \@answers);
    is sprintf('%.2f', $ck->kappa), '0.50', 'kappa';
    my $ci = $ck->confidence_interval(0.95);
    is sprintf('%.3f', $ci->[0]), 0.331, 'confidence interval start';
    is sprintf('%.3f', $ci->[1]), 0.669, 'confidence interval end';

};

subtest 'spssfocus' => sub {  # See also 02-weighted.t.
    plan(tests => 2);
    my @data = ([1, 1, 1], [1, 1, 3], [2, 1, 1], [1, 1, 1], [3, 2, 3],
                [3, 3, 2], [2, 2, 2], [1, 1, 1], [2, 2, 2], [3, 3, 3],
                [1, 1, 1], [1, 1, 1], [2, 2, 1], [1, 2, 1], [2, 1, 2],
                [3, 2, 2], [3, 3, 3], [2, 2, 3], [1, 1, 1], [1, 2, 1],
                [3, 3, 1], [1, 1, 1], [1, 1, 3], [1, 1, 2], [1, 1, 1]);

    my $ck1 = 'Statistics::Kappa::Cohen'->new(
        data => [map [@$_[0, 1]], @data]);
    is sprintf('%.3f', $ck1->kappa), 0.609, 'no weighting candidate 1';

    my $ck2 = 'Statistics::Kappa::Cohen'->new(
        data => [map [@$_[0, 2]], @data]);
    is sprintf('%.3f', $ck2->kappa), 0.414, 'no weighting candidate 2';
};

subtest 'Mary L McHugh' => sub {
    plan(tests => 4);
    my @answers;
    push @answers, ['normal', 'normal'] for 1 .. 147;
    push @answers, ['abnormal', 'abnormal'] for 1 .. 62;
    push @answers, ['normal', 'abnormal'] for 1 .. 10;
    push @answers, ['abnormal', 'normal'] for 1 .. 3;

    my $ck = 'Statistics::Kappa::Cohen'->new(data => \@answers);
    # The article says .85
    is sprintf('%.2f', $ck->kappa), 0.86, 'kappa';
    is sprintf('%.3f', $ck->standard_error), 0.037, 'standard error';

    # Values in the article are calculated from kappa = .85
    my $ci = $ck->confidence_interval(0.96);
    is sprintf('%.2f', $ci->[0]), 0.79, 'confidence interval start';
    is sprintf('%.2f', $ci->[1]), 0.94, 'confidence interval end';
}
