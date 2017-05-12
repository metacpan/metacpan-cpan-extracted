#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'SQL::Abstract::Query::Delete' );
    use_ok( 'SQL::Abstract::Query' );
}

my $query = SQL::Abstract::Query->new();

{
    my $delete = $query->delete('users');
    is(
        $delete->sql(),
        'DELETE FROM "users"',
        'basic delete',
    );
}

{
    my $delete = $query->delete('users', { user_id => 32 });
    is(
        $delete->sql(),
        'DELETE FROM "users" WHERE ( "user_id" = ? )',
        'delete with where',
    );
    is_deeply(
        [ $delete->original_values() ],
        ['32'],
        'values is correct',
    );
}

done_testing;
