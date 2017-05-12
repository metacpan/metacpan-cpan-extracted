use strict;
use warnings;

use Test::More;

use SQL::Composer::Expression;

subtest 'build raw' => sub {
    my $expr = SQL::Composer::Expression->new(expr => 'a = b');

    my $sql = $expr->to_sql;
    is $sql, 'a = b';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build raw ref' => sub {
    my $expr = SQL::Composer::Expression->new(expr => \'a = b');

    my $sql = $expr->to_sql;
    is $sql, 'a = b';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build raw with bind' => sub {
    my $expr = SQL::Composer::Expression->new(expr => \['a = ?', 'b']);

    my $sql = $expr->to_sql;
    is $sql, 'a = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];
};

subtest 'build simple' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [a => 'b']);

    my $sql = $expr->to_sql;
    is $sql, '`a` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];
};

subtest 'not modify original data' => sub {
    my $where = [a => 'b'];
    my $expr = SQL::Composer::Expression->new(expr => $where);

    is_deeply $where, [a => 'b'];
};

subtest 'build with column' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [a => {'-col' => 'b'}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` = `b`';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build with changed op' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [a => {'>' => 'b'}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` > ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b'];
};

subtest 'build with column and changed op' => sub {
    my $expr =
      SQL::Composer::Expression->new(expr => [a => {'>' => {'-col' => 'b'}}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` > `b`';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build as is' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [a => \'b']);

    my $sql = $expr->to_sql;
    is $sql, '`a` = b';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build as is with changed op' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [a => {'>' => \'b'}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` > b';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build as is with bind' => sub {
    my $expr =
      SQL::Composer::Expression->new(
        expr => [a => {'>' => \['length(?)' => 'hi']}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` > length(?)';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['hi'];
};

subtest 'build as is on the left' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [\'1' => 1]);

    my $sql = $expr->to_sql;
    is $sql, '1 = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['1'];
};

subtest 'build as is on the left with column' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [\'1' => {-col => 'column_name'}]);

    my $sql = $expr->to_sql;
    is $sql, '1 = `column_name`';

    my @bind = $expr->to_bind;
    is_deeply \@bind, [];
};

subtest 'build as is with bind on the left' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [\['length(?)', 5] => 1]);

    my $sql = $expr->to_sql;
    is $sql, 'length(?) = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['5', '1'];
};

subtest 'build IN' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [a => ['b', 'c', 'd']]);

    my $sql = $expr->to_sql;
    is $sql, '`a` IN (?,?,?)';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b', 'c', 'd'];
};

subtest 'build NOT IN' => sub {
    my $expr =
      SQL::Composer::Expression->new(expr => [a => {'NOT' => ['b', 'c', 'd']}]);

    my $sql = $expr->to_sql;
    is $sql, '`a` NOT IN (?,?,?)';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b', 'c', 'd'];
};

subtest 'build AND' => sub {
    my $expr = SQL::Composer::Expression->new(expr => [a => 'b', c => 'd']);

    my $sql = $expr->to_sql;
    is $sql, '`a` = ? AND `c` = ?';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b', 'd'];
};

subtest 'build OR' => sub {
    my $expr =
      SQL::Composer::Expression->new(expr => [-or => [a => 'b', c => 'd']]);

    my $sql = $expr->to_sql;
    is $sql, '(`a` = ? OR `c` = ?)';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b', 'd'];
};

subtest 'build mixed AND/OR' => sub {
    my $expr =
      SQL::Composer::Expression->new(
        expr => [-or => [a => 'b', -and => [c => 'd', 'e' => 'f']]]);

    my $sql = $expr->to_sql;
    is $sql, '(`a` = ? OR (`c` = ? AND `e` = ?))';

    my @bind = $expr->to_bind;
    is_deeply \@bind, ['b', 'd', 'f'];
};

done_testing;
