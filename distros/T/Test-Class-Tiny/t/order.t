#!/usr/bin/perl

package t::order;

use strict;
use warnings;

use Test::More;

t::order::TEST->runtests();

is_deeply(
    \@t::order::TEST::ORDER,
    [
        't::order::TEST::T2_a',
        't::order::TEST::T1_b',
        't::order::TEST::T2_b',
        't::order::TEST::T1_zz',
    ],
    'order of execution is as expected',
) or diag explain \@t::order::TEST::ORDER;

done_testing;

package t::order::TEST;

our @ORDER;

use Test2::V0;

use parent qw( Test::Class::Tiny );

sub T1_zz {
    push @ORDER, (caller 0)[3];
    ok 1;
}

sub T2_a {
    push @ORDER, (caller 0)[3];
    ok 1;
    ok 1;
}

sub T1_b {
    push @ORDER, (caller 0)[3];
    ok 1;
}

sub T2_b {
    push @ORDER, (caller 0)[3];
    ok 1;
    ok 1;
}

1;
