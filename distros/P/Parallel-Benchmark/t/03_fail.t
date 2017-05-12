# -*- mode:perl -*-
use strict;
use Test::More;

BEGIN { use_ok 'Parallel::Benchmark' }

my $bm = Parallel::Benchmark->new(
    setup => sub {
        my ($self, $n) = @_;
        if ( $n == 1 ) {
            sleep 2;
            die "died on setup";
        }
    },
    benchmark => sub {
        my ($self, $n) = @_;
        die "died on benchmark" if $n == 2;
        $self->stash->{counter}++;
        1;
    },
    teardown => sub {
        my ($self, $n) = @_;
        die "died on teardown" if $n == 3;
    },
    debug       => 1,
    concurrency => 3,
    time        => 1,
);

my $result = $bm->run;
isa_ok $result => "HASH";
is $result->{stashes}->{1}->{counter}, undef, "1 counter";
is $result->{stashes}->{2}->{counter}, undef, "2 counter";
ok $result->{stashes}->{3}->{counter}, "3 counter";
note explain $result;

done_testing;
