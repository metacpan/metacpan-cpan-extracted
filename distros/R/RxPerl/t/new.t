#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::SyncTimers ':all';

subtest 'rx_of' => sub {
    obs_is rx_of(), [ '' ], 'empty of';
    obs_is rx_of(10, 20, 30), [ '(abc)', { a => 10, b => 20, c => 30 } ], 'of with 3 values';
};

subtest 'rx_map' => sub {
    my $o = rx_interval(1)->pipe( op_map(sub {$_[0] * 10}), op_take(3) );
    obs_is $o, ['-abc', {a => 0, b => 10, c => 20}], 'map with three numbers';
};

subtest 'rx_filter' => sub {
    my $o = rx_interval(1)->pipe( op_filter(sub {$_[0] % 2 == 1}), op_take(3) );
    obs_is $o, ['--a-b-c', {a => 1, b => 3, c => 5}], 'filter with three/six values';
};

done_testing();
