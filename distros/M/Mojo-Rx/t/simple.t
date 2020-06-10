use strict;
use warnings;

use Test2::V0;

use Mojo::Rx ':all';

subtest 'event after unsubscribe' => sub {
    my $feed_cr;

    my $obs = rx_observable->new(sub {
        my ($emitter) = @_;
        $feed_cr = sub {$emitter->next(shift)};
        return;
    });

    my @got;

    my $subsc = $obs->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '_'},
    });

    $feed_cr->(9);
    $feed_cr->(8);
    $subsc->unsubscribe();
    $feed_cr->(7);

    is(\@got, [ 9, 8 ], 'expected events');
};

subtest 'of' => sub {
    my @got;

    rx_of(10, 20, 30)->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__DONE'},
    });

    is(\@got, [10, 20, 30, '__DONE'], 'expected events');
};

subtest 'merge sync' => sub {
    my @got;

    my @obss = (
        rx_of(10, 20, 30),
        rx_of(1, 2, 3),
    );

    my $merged = rx_merge(@obss);

    $merged->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__DONE'},
    });

    is(\@got, [10, 20, 30, 1, 2, 3, '__DONE'], 'expected events');
};

subtest 'no error' => sub {
    my $tore_down = 0;

    my $obs = rx_observable->new(sub {
        my ($emitter) = @_;

        $emitter->next('a');
        $emitter->next('b');
        $emitter->next('c');
        $emitter->complete();

        return sub { $tore_down = 1 };
    });

    my @got;

    my $subscr = $obs->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__COMPLETE__'},
    });

    is(\@got, [qw/ a b c __COMPLETE__ /], 'expected events');

    is($tore_down, 1, 'torn down before unsubscribe');

    $subscr->unsubscribe();

    is($tore_down, 1, 'still torn down after unsubscribe');
};

done_testing();
