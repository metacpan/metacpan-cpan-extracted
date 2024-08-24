#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::SyncTimers ':all';
use RxPerl::Extras ':all';

subtest 'op_exhaust_map_with_latest' => sub {
    my $o = rx_timer(0, 10)->pipe(
        op_take(3),
        op_switch_map(sub {
            my ($val) = @_;
            return rx_merge(
                rx_of($val),
                rx_of($val + 1)->pipe(op_delay(1)),
                rx_of($val + 2)->pipe(op_delay(2)),
            );
        }),
        op_exhaust_map_with_latest(sub {
            my ($val) = @_;
            return rx_timer(3)->pipe(op_map(sub { $val }));
        }),
    );
    obs_is $o, ['---0--2------1--3------2--4'], 'standard';

    my @storage;
    $o = rx_interval(3)->pipe(
        op_exhaust_map_with_latest(sub {
            push @storage, (my @args = @_);
            my $p = Mojo::Promise->new;
            rx_timer(7)->subscribe(sub { $p->resolve($args[0]) });
            return rx_from($p);
        }),
        op_take(2),
    );
    # obs_is $o, ['---1-1'], 'ex 2';
    # is \@storage, [0, 0, 2, 2], 'push args';
    obs_is $o, ['----------0------2'], 'marble 2';
    is \@storage, [0, 0, 2, 2], 'push args';
};

subtest 'op_throttle_time_with_both_leading_and_trailing' => sub {
    my $o = rx_timer(0, 1)->pipe(
        op_take(2),
        op_throttle_time_with_both_leading_and_trailing(3),
    );
    obs_is $o, ['01'], 'observable completes early';

    $o = rx_timer(0, 3)->pipe(
        op_throttle_time_with_both_leading_and_trailing(7),
        op_take(2),
    );
    obs_is $o, ['0------2'], 'observable completes normally';

    $o = rx_merge(
        rx_timer(2),
        rx_timer(10)->pipe(op_ignore_elements),
    )->pipe(
        op_throttle_time_with_both_leading_and_trailing(2),
    );
    obs_is $o, ['--0--------'], 'one event';
};

done_testing();
