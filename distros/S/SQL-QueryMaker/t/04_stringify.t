use strict;
use warnings;
use SQL::QueryMaker;
use Test::More;
use Test::Requires qw(
    DateTime
    Tie::IxHash
);

sub ordered_hashref {
    tie my %params, Tie::IxHash::, @_;
    return \%params;
}

subtest 'sql_and/hashref' => sub {
    my $q = sql_and(ordered_hashref(
        'a' => DateTime->new(year => 2025),
        'b' => 1,
    ));
    is $q->as_sql, '(`a` = ?) AND (`b` = ?)';
    is join(',', $q->bind), '2025-01-01T00:00:00,1';
};

subtest 'sql_or/valuelist' => sub {
    my $q = sql_or('a' => [
        DateTime->new(year => 2014),
        DateTime->new(year => 2015),
    ]);
    is $q->as_sql, '(`a` = ?) OR (`a` = ?)';
    is join(',', $q->bind), '2014-01-01T00:00:00,2015-01-01T00:00:00';
};

subtest 'sql_in' => sub {
    my $q = sql_in('a' => [
        DateTime->new(year => 2014),
        DateTime->new(year => 2015),
    ]);
    is $q->as_sql, '`a` IN (?,?)';
    is join(',', $q->bind), '2014-01-01T00:00:00,2015-01-01T00:00:00';
};

done_testing;
