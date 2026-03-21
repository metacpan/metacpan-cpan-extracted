use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# basic select
{
  my ($sql, @bind) = $q->select(
    -columns => ['id', 'name'],
    -from    => 'users',
  )->to_sql;
  is $sql, 'SELECT id, name FROM users', 'basic select';
  is_deeply \@bind, [], 'no binds';
}

# select *
{
  my ($sql, @bind) = $q->select(-from => 'users')->to_sql;
  is $sql, 'SELECT * FROM users', 'select star';
}

# select with where
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => 'users',
    -where   => { status => 'active' },
  )->to_sql;
  is $sql, 'SELECT * FROM users WHERE status = ?', 'select with where';
  is_deeply \@bind, ['active'], 'where bind';
}

# select with limit/offset
{
  my ($sql, @bind) = $q->select(
    -from    => 'users',
    -limit   => 10,
    -offset  => 20,
  )->to_sql;
  is $sql, 'SELECT * FROM users LIMIT ? OFFSET ?', 'limit offset';
  is_deeply \@bind, [10, 20], 'limit offset binds';
}

# select with order_by string
{
  my ($sql, @bind) = $q->select(
    -from     => 'users',
    -order_by => 'name',
  )->to_sql;
  is $sql, 'SELECT * FROM users ORDER BY name', 'order by string';
}

# select with order_by hash
{
  my ($sql, @bind) = $q->select(
    -from     => 'users',
    -order_by => [{ -desc => 'created_at' }],
  )->to_sql;
  is $sql, 'SELECT * FROM users ORDER BY created_at DESC', 'order by desc';
}

# select with order_by expr
{
  my ($sql, @bind) = $q->select(
    -from     => 'users',
    -order_by => [$q->col('name')->asc, $q->col('id')->desc],
  )->to_sql;
  is $sql, 'SELECT * FROM users ORDER BY name ASC, id DESC', 'order by expr';
}

# select with group_by and having (raw expression)
{
  my ($sql, @bind) = $q->select(
    -columns  => ['department', $q->func('COUNT', '*')->as('cnt')],
    -from     => 'employees',
    -group_by => 'department',
    -having   => $q->raw('COUNT(*) > ?', 5),
  )->to_sql;
  like $sql, qr/GROUP BY department/, 'group by';
  like $sql, qr/HAVING COUNT\(\*\) > \?/, 'having';
  is_deeply \@bind, [5], 'having bind';
}

# select with table|alias
{
  my ($sql, @bind) = $q->select(
    -columns => ['u.id', 'u.name'],
    -from    => 'users|u',
  )->to_sql;
  is $sql, 'SELECT u.id, u.name FROM users u', 'table alias';
}

# select with multiple from items
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => ['users|u', $q->join('orders|o', 'u.id = o.user_id')],
  )->to_sql;
  is $sql, 'SELECT * FROM users u JOIN orders o ON u.id = o.user_id', 'from with join';
}

# select with func column and val bind
{
  my ($sql, @bind) = $q->select(
    -columns => [$q->func('COALESCE', 'nickname', $q->val('Anonymous'))->as('display')],
    -from    => 'users',
  )->to_sql;
  is $sql, 'SELECT COALESCE(nickname, ?) AS display FROM users', 'func in columns';
  is_deeply \@bind, ['Anonymous'], 'func bind in columns';
}

# select with named windows
{
  my ($sql, @bind) = $q->select(
    -columns => [
      'name',
      $q->func('RANK')->over('w')->as('rnk'),
    ],
    -from    => 'employees',
    -window  => {
      w => {
        '-partition_by' => 'department',
        '-order_by'     => [{ -desc => 'salary' }],
      },
    },
  )->to_sql;
  like $sql, qr/RANK\(\) OVER w AS rnk/, 'named window in column';
  like $sql, qr/WINDOW w AS \(PARTITION BY department ORDER BY salary DESC\)/, 'window definition';
}

# SELECT DISTINCT via -distinct arg
{
  my ($sql, @bind) = $q->select(
    -distinct => 1,
    -columns  => ['department'],
    -from     => 'employees',
  )->to_sql;
  is $sql, 'SELECT DISTINCT department FROM employees', 'distinct via arg';
}

# SELECT DISTINCT via ->distinct modifier
{
  my $base = $q->select(-columns => ['department'], -from => 'employees');
  my ($sql) = $base->distinct->to_sql;
  is $sql, 'SELECT DISTINCT department FROM employees', 'distinct via modifier';

  # base unchanged
  my ($base_sql) = $base->to_sql;
  is $base_sql, 'SELECT department FROM employees', 'base unchanged after distinct';
}

# empty having clause omitted
{
  my ($sql, @bind) = $q->select(
    -columns  => ['department', $q->func('COUNT', '*')->as('cnt')],
    -from     => 'employees',
    -group_by => 'department',
    -having   => {},
  )->to_sql;
  unlike $sql, qr/HAVING/, 'empty having omitted';
}
{
  my ($sql, @bind) = $q->select(
    -columns  => ['department', $q->func('COUNT', '*')->as('cnt')],
    -from     => 'employees',
    -group_by => 'department',
    -having   => [],
  )->to_sql;
  unlike $sql, qr/HAVING/, 'empty arrayref having omitted';
}

done_testing;
