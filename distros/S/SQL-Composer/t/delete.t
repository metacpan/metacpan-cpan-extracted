use strict;
use warnings;

use Test::More;

use SQL::Composer::Delete;

subtest 'build simple' => sub {
    my $expr = SQL::Composer::Delete->new(from => 'table');

    my $sql = $expr->to_sql;
    is $sql, 'DELETE FROM `table`';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];

    is 'table', $expr->table;
};

subtest 'build with where' => sub {
    my $expr = SQL::Composer::Delete->new(from => 'table', where => [a => 'b']);

    my $sql = $expr->to_sql;
    is $sql, 'DELETE FROM `table` WHERE `a` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];
};

subtest 'build with limit' => sub {
    my $expr = SQL::Composer::Delete->new(
        from  => 'table',
        limit => 5
    );

    my $sql = $expr->to_sql;
    is $sql, 'DELETE FROM `table` LIMIT 5';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build with limit and offset' => sub {
    my $expr = SQL::Composer::Delete->new(
        from   => 'table',
        limit  => 5,
        offset => 10
    );

    my $sql = $expr->to_sql;
    is $sql, 'DELETE FROM `table` LIMIT 5 OFFSET 10';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

done_testing;
