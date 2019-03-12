#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 1;

use SQL::Tiny ':all';

test_insert(
    'users',
    {
        serialno   => '12345',
        name       => 'Dave',
        rank       => 'Sergeant',
        height     => undef,
        date_added => \'SYSDATE()',
    },

    'INSERT INTO users (date_added,height,name,rank,serialno) VALUES (SYSDATE(),NULL,?,?,?)',
    [ 'Dave', 'Sergeant', 12345 ]
);


done_testing();

exit 0;

sub test_insert {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $table          = shift;
    my $values         = shift;
    my $expected_sql   = shift;
    my $expected_binds = shift;

    return subtest "Expecting: $expected_sql" => sub {
        plan tests => 2;

        my ($sql,$binds) = sql_insert( $table, $values );
        is( $sql, $expected_sql, 'SQL matches' );
        is_deeply( $binds, $expected_binds, 'Binds match' );
    };
}
