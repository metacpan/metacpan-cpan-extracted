# -*- mode:perl -*-
use strict;
use Test::More;

BEGIN { use_ok 'Parallel::Benchmark' }

my $bm = Parallel::Benchmark->new(
    setup => sub {
        my ($self, $n) = @_;
        warn "setup $n";
    },
    benchmark => sub {
        my ($self, $n) = @_;
        sleep 1;
        warn "CHILD $n";
        $self->stash->{child_id} = $n;
        return 1;
    },
    teardown => sub {
        my ($self, $n) = @_;
        warn "teardown $n";
    },
    debug       => 1,
    concurrency => 3,
);

my $result = $bm->run;
isa_ok $result => "HASH";
ok exists $result->{score},   "score exists";
ok exists $result->{elapsed}, "elapsed exists";
isa_ok $result->{stashes} => "HASH";
is $result->{stashes}->{1}->{child_id} => 1;
is $result->{stashes}->{2}->{child_id} => 2;
is $result->{stashes}->{3}->{child_id} => 3;
note explain $result;

done_testing;
