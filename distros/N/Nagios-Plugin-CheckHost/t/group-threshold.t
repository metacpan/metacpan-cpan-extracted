#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Monitoring::Plugin::Threshold;
use Monitoring::Plugin::Functions qw(:all);
use_ok 'Nagios::Plugin::Threshold::Group';

my $SINGLE_CRITICAL = 4;
my $SINGLE_WARNING  = 2;
my $GROUP_CRITICAL  = 3;
my $GROUP_WARNING   = 1;

my $single_threshold = Monitoring::Plugin::Threshold->new(
    critical => $SINGLE_CRITICAL,
    warning  => $SINGLE_WARNING,
);

my $group_threshold = Monitoring::Plugin::Threshold->new(
    critical => $GROUP_CRITICAL,
    warning  => $GROUP_WARNING,
);

subtest 'everything is ok if every value just in range' => sub {
    my $gt = new_ok 'Nagios::Plugin::Threshold::Group', [
        single_threshold => $single_threshold,
        group_threshold  => $group_threshold,
    ];

    my @values;

    # Just one warning, it is allowed for OK
    push @values, $SINGLE_WARNING + 1;

    # And a lot of OK values
    push @values, $SINGLE_WARNING for 1 .. $GROUP_CRITICAL;

    is $gt->get_status(\@values), OK, 'ok status';
};

subtest 'we may got warning if we got '
  . 'critical + warning > group_warning' => sub {
    my $gt = new_ok 'Nagios::Plugin::Threshold::Group', [
        single_threshold => $single_threshold,
        group_threshold  => $group_threshold,
    ];
    my @values;

    # Recipe for a warning:
    # make single warning
    push @values, $SINGLE_WARNING+1;

    # add critical for a taste
    push @values, $SINGLE_CRITICAL+1;

    # and some OKs
    push @values, $SINGLE_WARNING for 1 .. 2;

    is $gt->get_status(\@values), WARNING, 'warning status';
};

subtest 'you have to be critical to make it critical' => sub {
    my $gt = new_ok 'Nagios::Plugin::Threshold::Group', [
        single_threshold => $single_threshold,
        group_threshold  => $group_threshold,
    ];

    my @values;

    push @values, $SINGLE_CRITICAL + 1 for 1 .. $GROUP_CRITICAL;

    # Just a warning to prove that warning do not cause critical
    push @values, $SINGLE_WARNING+1;
    is $gt->get_status(\@values), WARNING, 'not a critical, yet..';

    push @values, $SINGLE_CRITICAL + 1;
    is $gt->get_status(\@values), CRITICAL, 'we been critical and it is critical now';
};

done_testing();
