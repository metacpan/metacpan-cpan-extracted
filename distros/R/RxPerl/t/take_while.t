use strict;
use warnings;
use Test::More;

use RxPerl ':all';

my @got;

rx_of(10, 20, 30, 40, 50, 60, 70, 80, 90, 100)->pipe(
    op_take_while(sub {$_[0] <= 50}),
)->subscribe(sub {
    push @got, $_[0];
});

is_deeply \@got, [10, 20, 30, 40, 50], 'got correct values';

undef @got;

rx_of(10, 20, 30, 40, 50, 60, 70, 80, 90, 100)->pipe(
    op_take_while(sub {$_[0] <= 50}, 1),
)->subscribe(sub {
    push @got, $_[0];
});

is_deeply \@got, [10, 20, 30, 40, 50, 60], 'got correct values';

done_testing();

