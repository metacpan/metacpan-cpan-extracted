#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::SyncTimers ':all';

subtest 'subject_order' => sub {
    my @orders;

    for (1 .. 20) {
        my @order;
        my $subject = rx_subject->new;
        $subject->subscribe(sub { push @order, 1 });
        $subject->subscribe(sub { push @order, 2 });
        $subject->next(1);

        push @orders, \@order;
    }

    is \@orders, [ ([1, 2]) x 20 ], 'correct order';
};

subtest 'behavior_subject' => sub {
    my $o = rx_behavior_subject->new(10);
    is $o->get_value, 10, 'correct value';
    $o->next(20);
    is $o->get_value, 20, 'correct value';
    $o->complete;
    is $o->get_value, 20, 'correct value after complete';
};

done_testing;
