use strict;
use warnings;
use SQL::QueryMaker;
use Test::More;
use Test::Requires 'Tie::IxHash';

sub ordered_hashref {
    tie my %params, Tie::IxHash::, @_;
    return \%params;
}

my $q = sql_and(ordered_hashref(foo => 1, bar => sql_eq(2), baz => sql_lt(3)));

is $q->as_sql, '(`foo` = ?) AND (`bar` = ?) AND (`baz` < ?)';
is_deeply [$q->bind], [1,2,3];

done_testing;
