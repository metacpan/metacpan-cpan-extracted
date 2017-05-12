#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'SQL::Abstract::Query::Update' );
    use_ok( 'SQL::Abstract::Query' );
}

my $query = SQL::Abstract::Query->new();

{
    my $update = $query->update('users', ['foo']);
    is(
        $update->sql(),
        'UPDATE "users" SET "foo" = ?',
        'basic update',
    );

    is_deeply(
        [ $update->original_values() ],
        ['foo'],
        'original values is correct',
    );

    is_deeply(
        [ $update->values({foo=>32}) ],
        [32],
        'values is correct',
    );
}

{
    my ($sql, @bind_values) = $query->update('users', {foo => 32});
    is(
        $sql,
        'UPDATE "users" SET "foo" = ?',
        'basic update using non-OO API',
    );
}

done_testing;
