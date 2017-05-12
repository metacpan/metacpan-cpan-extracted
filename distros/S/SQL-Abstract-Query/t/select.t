#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'SQL::Abstract::Query::Select' );
    use_ok( 'SQL::Abstract::Query' );
}

my $query = SQL::Abstract::Query->new();

# JOIN

{
    my $select = $query->select(
        ['users.user_id', 'email' ],
        ['users', 'user_emails'],
        { 'user_emails.user_id' => \'= users.user_id' },
    );

    is(
        $select->sql(),
        'SELECT "users"."user_id", "email" FROM "users", "user_emails" WHERE ( "user_emails"."user_id" = users.user_id )',
        'implicit joins',
    );
}

{
    my $select = $query->select(
        ['users.user_id', 'email'],
        [
            'users',
            { name => 'user_emails', using => 'user_id' },
        ],
    );

    is(
        $select->sql(),
        'SELECT "users"."user_id", "email" FROM "users" JOIN "user_emails" ON ( "user_emails"."user_id" = "users"."user_id" )',
        'explicit joins',
    );
}

# GROUP BY

{
    my $select = $query->select(
        ['gender', \'AVG(age)'],
        'users',
        undef,
        { group_by => 'gender' },
    );

    is(
        $select->sql(),
        'SELECT "gender", AVG(age) FROM "users" GROUP BY "gender"',
        'scalar group by',
    );
}

{
    my $select = $query->select(
        ['gender', 'title', \'AVG(age)'],
        'users',
        undef,
        { group_by => ['gender', 'title'] },
    );

    is(
        $select->sql(),
        'SELECT "gender", "title", AVG(age) FROM "users" GROUP BY "gender", "title"',
        'array group by',
    );
}

# ORDER BY

{
    my $select = $query->select(
        ['name', 'age'],
        'users',
        undef,
        { order_by => 'age' },
    );

    is(
        $select->sql(),
        'SELECT "name", "age" FROM "users" ORDER BY "age"',
        'scalar order by',
    );
}

{
    my $select = $query->select(
        ['name', 'age', 'height'],
        'users',
        undef,
        { order_by => [{'age' => 'desc'}, 'height'] },
    );

    is(
        $select->sql(),
        'SELECT "name", "age", "height" FROM "users" ORDER BY "age" DESC, "height"',
        'hash order by',
    );
}

# LIMIT

{
    my $query = SQL::Abstract::Query->new( SQL::Dialect->new(limit=>'offset') );

    my $select = $query->select(
        ['user_id'],
        'users',
        undef,
        { limit => 20, offset => 100 },
    );

    is(
        $select->sql(),
        'SELECT "user_id" FROM "users" LIMIT ? OFFSET ?',
        'offset limit dialect sql',
    );

    is_deeply(
        [ $select->original_values() ],
        [20, 100],
        'offset limit dialect values',
    );
}

{
    my $query = SQL::Abstract::Query->new( SQL::Dialect->new(limit=>'xy') );

    my $select = $query->select(
        ['user_id'],
        'users',
        undef,
        { limit => 20, offset => 100 },
    );

    is(
        $select->sql(),
        'SELECT "user_id" FROM "users" LIMIT ?, ?',
        'xy limit dialect sql',
    );

    is_deeply(
        [ $select->original_values() ],
        [100, 20],
        'xy limit dialect values',
    );
}

{
    my $query = SQL::Abstract::Query->new( SQL::Dialect->new(rownum=>1) );

    my $select = $query->select(
        ['user_id'],
        'users',
        undef,
        { limit => 20, offset => 100 },
    );

    is(
        $select->sql(),
        'SELECT * FROM ( SELECT "A".*, ROWNUM "r" FROM ( SELECT "user_id" FROM "users" ) "A" WHERE ROWNUM <= ? + ? ) "B" WHERE "r" > ?',
        'rownum limit dialect sql',
    );

    is_deeply(
        [ $select->original_values() ],
        [20, 100, 100],
        'rownum limit dialect values',
    );
}

# ALL TOGETHER NOW!

{
    my $query = SQL::Abstract::Query->new( SQL::Dialect->new(limit=>'offset') );

    my $select = $query->select(
        ['u.user_id', 'e.address', \'MAX(logs.level)'],
        [ {'users' => 'u'}, {name=>'user_emails', as=>'e', on=>{'e.user_id' => \'= u.user_id'}}, 'logs' ],
        { 'logs.user_id' => \'= u.user_id' },
        { order_by => 'u.user_id', group_by => [qw( u.user_id e.adress )], limit => 20, offset => 100 },
    );

    is(
        $select->sql(),
        'SELECT "u"."user_id", "e"."address", MAX(logs.level) FROM "users" "u" JOIN "user_emails" "e" ON ( "e"."user_id" = u.user_id ), "logs" WHERE ( "logs"."user_id" = u.user_id ) GROUP BY "u"."user_id", "e"."adress" ORDER BY "u"."user_id" LIMIT ? OFFSET ?',
        'joins, ordery by, group by, and limit',
    );
}

done_testing;
