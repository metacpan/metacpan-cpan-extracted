#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'SQL::Abstract::Query::Insert' );
    use_ok( 'SQL::Abstract::Query' );
}

my $query = SQL::Abstract::Query->new();

{
    my $insert = $query->insert('users', ['foo']);
    is(
        $insert->sql(),
        'INSERT INTO "users" ( "foo") VALUES ( ? )',
        'basic insert',
    );

    is_deeply(
        [ $insert->original_values() ],
        ['foo'],
        'original values is correct',
    );

    is_deeply(
        [ $insert->values({foo=>32}) ],
        [32],
        'values is correct',
    );
}

{
    my ($sql, @bind_values) = $query->insert('users', {foo => 32});
    is(
        $sql,
        'INSERT INTO "users" ( "foo") VALUES ( ? )',
        'SQL for non-OO insert are correct',
    );

    is_deeply(
        \@bind_values,
        [32],
        'bind values for non-OO insert are correct',
    );
}

done_testing;
