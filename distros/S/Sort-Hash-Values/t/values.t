use strict;
use warnings;
use Test::More tests => 5;
use Test::Differences;
use List::Util qw(max);
BEGIN {
    use_ok 'Sort::Hash::Values';
}
# From module synopsis
my %birth_dates = (
    Larry  => 1954,
    Randal => 1961,
    Damian => 1964,
    Simon  => 1978,
    Mark   => 1965,
    Jesse  => 1976,
);

eq_or_diff
    [sort_values { $a <=> $b } %birth_dates],
    [qw(Larry Randal Damian Mark Jesse Simon)],
    'Basic sanity test',
;

my %structures = (
    foo => [1, 2, 3],
    bar => [1, 2, 4],
    baz => [1, 2, 2],
    quz => [1, 3, 1],
    lol => [42],
);

eq_or_diff
    [sort_values {
        for (0 .. max $#$a, $#$b) {
            my $comparator = $a->[$_] <=> $b->[$_];
            return $comparator if $comparator;
        }
    } %structures],
    [qw(baz foo bar quz lol)],
    'Complex sorting functions'
;

eq_or_diff
    [sort_values { die "Shouldn't happen" }],
    [],
    'Empty hash'
;

eq_or_diff
    [sort_values { die "Shouldn't happen" } a => "b"],
    ['a'],
    'Single element hash'
;
