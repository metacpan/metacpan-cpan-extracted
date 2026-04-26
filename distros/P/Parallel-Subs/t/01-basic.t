use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

# Constructor with various options
my @option_sets = (
    {},
    { max_process         => 1 },
    { max_process_per_cpu => 2 },
    { max_memory          => 128 },
);

for my $opts (@option_sets) {
    my $label = %$opts ? join( ', ', map { "$_ => $opts->{$_}" } keys %$opts ) : 'defaults';

    my $p = Parallel::Subs->new(%$opts);
    isa_ok $p, 'Parallel::Subs';

    ok $p->add( sub { 1 } ),                     "add scalar job ($label)";
    ok $p->add( sub { "string" } ),               "add string job ($label)";
    ok $p->add( sub { { hash => 42 } } ),          "add hash job ($label)";
    ok $p->add( sub { [ 1 .. 5 ] } ),              "add array job ($label)";
    ok $p->run(),                                   "run ($label)";

    is $p->results(), [
        1,
        'string',
        { hash => 42 },
        [ 1 .. 5 ],
    ], "results match ($label)";
}

# Multiple jobs returning hashes — no sleeps needed
subtest 'multiple hash-returning jobs' => sub {
    my $p = Parallel::Subs->new();

    my @words = qw(a list of jobs to run);
    for my $word (@words) {
        ok $p->add( sub { compute($word) } ), "add job '$word'";
    }

    ok $p->run(), "run all jobs";

    my $results = $p->results();
    is scalar @$results, scalar @words, "got one result per job";

    for my $i ( 0 .. $#words ) {
        is $results->[$i]{job}, $words[$i], "result $i has correct job name";
        is $results->[$i]{"your data key for $words[$i]"}, length( $words[$i] ),
            "result $i has correct computed value";
    }
};

done_testing;

sub compute {
    my $word = shift || '';
    return {
        job                        => $word,
        "your data key for $word"  => length($word),
    };
}
