use strict;
use warnings;
use Test::More;

use RxPerl::Mojo ':all';
use Mojo::Promise;
use Mojo::IOLoop;

subtest 'rx_from(arrayref)' => sub {
    my @got;

    rx_from([10, 20, 30])->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__DONE'},
    });

    is_deeply \@got, [10, 20, 30, '__DONE'], 'got correct values';
};

subtest 'rx_from(promise)' => sub {
    my @got;

    my $p1 = Mojo::Promise->new;
    my $p2 = Mojo::Promise->new;

    my $subscriber = {
        next     => sub {push @got, shift},
        error    => sub {push @got, "error:".shift},
        complete => sub {push @got, '__DONE'},
    };

    rx_from($p1)->subscribe($subscriber);
    Mojo::IOLoop->one_tick;
    is_deeply \@got, [], 'no events';

    $p1->resolve(100);
    Mojo::IOLoop->one_tick;
    is_deeply \@got, [100, '__DONE'], 'next & complete events';

    @got = ();
    rx_from($p2)->subscribe($subscriber);
    $p2->reject('200');
    Mojo::IOLoop->one_tick;
    is_deeply \@got, ['error:200'], 'error event';
};

subtest 'rx_from(observable)' => sub {
    my @got;

    my $o = rx_of(50, 100, 150);

    my $subscriber = {
        next     => sub {push @got, shift},
        error    => sub {push @got, "error:".shift},
        complete => sub {push @got, '__DONE'},
    };

    rx_from($o)->subscribe($subscriber);

    is_deeply \@got, [50, 100, 150, '__DONE'], 'got correct values';
};

done_testing();

