use strict;
use warnings;

use Test::More;

use SQL::Composer::Update;

subtest 'build simple' => sub {
    my $expr =
      SQL::Composer::Update->new(table => 'table', values => [a => 'b']);

    my $sql = $expr->to_sql;
    is $sql, 'UPDATE `table` SET `a` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];

    is 'table', $expr->table;
};

subtest 'build simple with as is' => sub {
    my $expr =
      SQL::Composer::Update->new(table => 'table', values => [foo => \"'bar'"]);

    my $sql = $expr->to_sql;
    is $sql, q{UPDATE `table` SET `foo` = 'bar'};

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build with as is and bind values' => sub {
    my $expr = SQL::Composer::Update->new(
        table  => 'table',
        values => [foo => \['NOW() + INTERVAL ?', 15]]
    );

    my $sql = $expr->to_sql;
    is $sql, q{UPDATE `table` SET `foo` = NOW() + INTERVAL ?};

    my @bind = $expr->to_bind;
    is_deeply \@bind, [15];
};

subtest 'build with where' => sub {
    my $expr = SQL::Composer::Update->new(
        table  => 'table',
        values => [a => 'b'],
        where  => [c => 'd']
    );

    my $sql = $expr->to_sql;
    is $sql, 'UPDATE `table` SET `a` = ? WHERE `c` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b', 'd'];
};

subtest 'build with limit' => sub {
    my $expr = SQL::Composer::Update->new(
        table  => 'table',
        values => [foo => 'bar'],
        limit  => 5
    );

    my $sql = $expr->to_sql;
    is $sql, 'UPDATE `table` SET `foo` = ? LIMIT 5';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['bar'];
};

subtest 'build with limit and offset' => sub {
    my $expr = SQL::Composer::Update->new(
        table  => 'table',
        values => [foo => 'bar'],
        limit  => 5,
        offset => 10
    );

    my $sql = $expr->to_sql;
    is $sql, 'UPDATE `table` SET `foo` = ? LIMIT 5 OFFSET 10';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['bar'];
};

done_testing;
