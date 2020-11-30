use strict;
use warnings;

use Test2::V0;

use RxPerl ':all';

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

subtest 'behavior subject' => sub {
    my $bs = rx_behavior_subject->new(10);
    my @got;
    $bs->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__COMPLETE__'},
    });
    $bs->next(20);
    $bs->next(30);
    $bs->complete;

    is(\@got, [10, 20, 30, '__COMPLETE__'], 'expected events');

    #### subscribe behavior_subject to an observable ####

    $bs = rx_behavior_subject->new(10);
    undef @got;
    my $s = rx_subject->new;
    $s->subscribe($bs);
    $s->next(20);

    $bs->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__COMPLETE__'},
    });

    $s->next(30);
    $s->complete;

    is(\@got, [20, 30, '__COMPLETE__'], 'expected events');
};

subtest 'replay subject' => sub {
    my $rs = rx_replay_subject->new(2);
    my @got;

    $rs->next(10);
    $rs->next(20);
    $rs->next(30);

    $rs->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__COMPLETE__'},
    });

    $rs->next(40);
    $rs->next(50);
    $rs->complete;

    is \@got, [20, 30, 40, 50, '__COMPLETE__'], 'expected events';

    undef @got;
    $rs->subscribe({
        next     => sub {push @got, shift},
        complete => sub {push @got, '__COMPLETE__'},
    });

    is \@got, [40, 50, '__COMPLETE__'], 'expected events';
};

done_testing();
