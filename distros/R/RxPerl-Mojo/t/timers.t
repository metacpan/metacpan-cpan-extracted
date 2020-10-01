use v5.10;
use strict;
use warnings;
use Test2::V0;

use RxPerl::Mojo ':all';
use Mojo::IOLoop;

subtest 'timer' => sub {
    my @got;
    rx_timer(0.1, 0.1)->pipe(
        op_take(3),
    )->subscribe(
        sub {push @got, $_[0]},
        sub {die},
        sub {push @got, '__DONE'},
    );

    Mojo::IOLoop->start;

    is \@got, [0, 1, 2, '__DONE'], 'timer ok';
};

done_testing();

