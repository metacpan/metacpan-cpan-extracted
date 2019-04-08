#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 3;

use SQL::Tiny ':all';

test_update(
    'users',
    {
        lockdate => undef,
        qty      => \[ 'TRUNC(?)', 19.85 ],
        status   => 'X',
    },
    {
        orderdate => \'SYSDATE()',
        qty       => \[ 'ROUND(?)', 14.5 ],
    },

    'UPDATE users SET lockdate=NULL, qty=TRUNC(?), status=? WHERE orderdate=SYSDATE() AND qty=ROUND(?)',
    [ 19.85, 'X', 14.5 ],

    'Standard mish-mash'
);

test_update(
    'wipe',
    {
        finagle => 4,
    },
    {},

    'UPDATE wipe SET finagle=?',
    [ 4 ],

    'No WHERE restrictions'
);

test_update(
    'fishy',
    {
        bingo => 'bongo',
    },
    {
        status => [qw( A B C )],
        width  => [ 5, 6 ],
    },

    'UPDATE fishy SET bingo=? WHERE status IN (?,?,?) AND width IN (?,?)',
    [ 'bongo', 'A', 'B', 'C', 5, 6 ],

    'WHERE clause has INs',
);


done_testing();

exit 0;

sub test_update {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $table          = shift;
    my $values         = shift;
    my $where          = shift;
    my $expected_sql   = shift;
    my $expected_binds = shift;
    my $msg            = shift;

    return subtest "$msg: $expected_sql" => sub {
        plan tests => 2;

        my ($sql,$binds) = sql_update( $table, $values, $where );
        is( $sql, $expected_sql, 'SQL matches' );
        is_deeply( $binds, $expected_binds, 'Binds match' );
    };
}
