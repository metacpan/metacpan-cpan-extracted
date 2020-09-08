use strict;
use warnings;
use Test::More;

use RxPerl::Mojo ':all';

subtest 'start "of" with 100' => sub {
    my @got;

    rx_of(0, 1, 2, 3)->pipe(
        op_start_with(100, 200),
    )->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__DONE'},
    });

    is_deeply \@got, [100, 200, 0, 1, 2, 3, '__DONE'], 'got correct values';
};

subtest 'start empty "of" with 100' => sub {
    my @got;

    rx_of(0, 1, 2, 3)->pipe(
        op_start_with(100),
        op_take(0),
    )->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__DONE'},
    });

    is_deeply \@got, ['__DONE'], 'got correct values';
};

done_testing();
