use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

subtest 'single job with callback' => sub {
    my $p = Parallel::Subs->new();
    $p->add(
        sub { return { number => 1 } },
        sub {
            my $result = shift;
            is $result->{number}, 1, "callback receives correct result";
        }
    );
    $p->wait_for_all();
};

subtest 'multiple jobs with callbacks' => sub {
    my $n = 5;
    my $p = Parallel::Subs->new();

    for my $i ( 1 .. $n ) {
        $p->add(
            sub { return { number => $i } },
            sub {
                my $result = shift;
                is $result->{number}, $i, "callback $i receives number=$i";
            }
        );
    }

    note "running $n jobs in parallel";
    $p->wait_for_all();
};

done_testing;
