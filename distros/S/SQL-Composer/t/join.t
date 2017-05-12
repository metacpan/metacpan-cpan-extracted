use strict;
use warnings;
use Test::More;

use SQL::Composer::Join;

subtest 'build simple' => sub {
    my $expr = SQL::Composer::Join->new(source => 'table', on => [a => 'b']);

    my $sql = $expr->to_sql;
    is $sql, 'JOIN `table` ON `table`.`a` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];
};

subtest 'build simple with as' => sub {
    my $expr = SQL::Composer::Join->new(
        source => 'table',
        as     => 'another_table',
        on     => [a => 'b']
    );

    my $sql = $expr->to_sql;
    is $sql, 'JOIN `table` AS `another_table` ON `another_table`.`a` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];
};

subtest 'build with op' => sub {
    my $expr = SQL::Composer::Join->new(
        op     => 'left natural',
        source => 'table',
        on     => [a => 'b']
    );

    my $sql = $expr->to_sql;
    is $sql, 'LEFT NATURAL JOIN `table` ON `table`.`a` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];
};

subtest 'build with using' => sub {
    my $expr = SQL::Composer::Join->new(
        op     => 'left natural',
        source => 'table',
        using  => 'column'
    );

    my $sql = $expr->to_sql;
    is $sql, 'LEFT NATURAL JOIN `table` USING `column`';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

done_testing;
