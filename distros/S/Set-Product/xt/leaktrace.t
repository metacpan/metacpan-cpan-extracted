use strict;
use warnings;
use Test::More;
use Set::Product::PP qw(product);

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};

my @set = (
    [qw(one two three four)],
    [qw(a b c d e)],
    [qw(foo bar blah)],
    [1..5], [1..3], [1..4]
);

my $try = sub {
    my @s;
    product { push @s, @_ } @set for 1 .. 100;
};

$try->();

is(leaked_count($try), 0, 'leaks');

done_testing;
