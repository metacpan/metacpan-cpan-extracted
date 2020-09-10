use strict;
use warnings;
use Test::More;

use RxPerl ':all';

my @got;

# 10, undef, 20, 30, [], []
rx_of(10, 10, undef, undef, 20, 20, 20, 30, 30, [], [])->pipe(
    op_distinct_until_changed(),
)->subscribe(
    sub {push @got, $_[0]},
    undef,
    sub {push @got, '__DONE'},
);

is_deeply \@got, [10, undef, 20, 30, [], [], '__DONE'], 'got correct values';

done_testing();
