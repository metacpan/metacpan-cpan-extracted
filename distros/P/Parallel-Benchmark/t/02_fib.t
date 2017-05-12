# -*- mode:perl -*-
use strict;
use Test::More;

BEGIN { use_ok 'Parallel::Benchmark' }

sub fib {
    my $n = shift;
    return 0 if $n == 0;
    return 1 if $n == 1;
    fib($n - 1) + fib($n - 2);
}

is fib(10) => 55, "fib(10) == 55";

my $bm = Parallel::Benchmark->new(
    benchmark => sub {
        my ($self, $n) = @_;
        fib(10);
        return 1;
    },
    debug       => 1,
    concurrency => 3,
);

my $result = $bm->run;
isa_ok $result => "HASH";
ok exists $result->{score},   "score exists";
ok exists $result->{elapsed}, "elapsed exists";
note explain $result;

done_testing;
