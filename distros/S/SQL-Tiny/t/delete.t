#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 3;

use SQL::Tiny ':all';

test_delete(
    'users',
    {
        serialno   => 12345,
        height     => undef,
        date_added => \'SYSDATE()',
        status     => [qw( X Y Z )],
        qty        => \[ 'ROUND(?)', 14.5 ],
    },

    'DELETE FROM users WHERE date_added=SYSDATE() AND height IS NULL AND qty=ROUND(?) AND serialno=? AND status IN (?,?,?)',
    [ 14.5, 12345, 'X', 'Y', 'Z' ],

    'Standard mish-mash'
);

test_delete(
    'doomed',
    {},

    'DELETE FROM doomed',
    [],

    'No WHERE conditions'
);

test_delete(
    'orders',
    { status => undef },

    'DELETE FROM orders WHERE status IS NULL',
    [],

    'No WHEREs with values'
);


done_testing();

exit 0;

sub test_delete {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $table          = shift;
    my $where          = shift;
    my $expected_sql   = shift;
    my $expected_binds = shift;
    my $msg            = shift;

    return subtest "$msg: $expected_sql" => sub {
        plan tests => 2;

        my ($sql,$binds) = sql_delete( $table, $where );
        is( $sql, $expected_sql, 'SQL matches' );
        is_deeply( $binds, $expected_binds, 'Binds match' );
    };
}
