use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# inner join
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => ['users|u', $q->join('orders|o', 'u.id = o.user_id')],
  )->to_sql;
  is $sql, 'SELECT * FROM users u JOIN orders o ON u.id = o.user_id', 'inner join';
}

# left join
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => ['users|u', $q->left_join('payments|p', 'u.id = p.user_id')],
  )->to_sql;
  is $sql, 'SELECT * FROM users u LEFT JOIN payments p ON u.id = p.user_id', 'left join';
}

# right join
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => ['users|u', $q->right_join('returns|r', 'u.id = r.user_id')],
  )->to_sql;
  is $sql, 'SELECT * FROM users u RIGHT JOIN returns r ON u.id = r.user_id', 'right join';
}

# full outer join
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => ['users|u', $q->full_join('archive|a', 'u.id = a.user_id')],
  )->to_sql;
  is $sql, 'SELECT * FROM users u FULL OUTER JOIN archive a ON u.id = a.user_id', 'full outer join';
}

# cross join
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => ['users', $q->cross_join('multiplier')],
  )->to_sql;
  is $sql, 'SELECT * FROM users CROSS JOIN multiplier', 'cross join';
}

# multiple joins
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => [
      'users|u',
      $q->join('orders|o', 'u.id = o.user_id'),
      $q->left_join('payments|p', 'o.id = p.order_id'),
    ],
  )->to_sql;
  is $sql,
    'SELECT * FROM users u JOIN orders o ON u.id = o.user_id LEFT JOIN payments p ON o.id = p.order_id',
    'multiple joins';
}

# join with hashref ON condition
{
  my ($sql, @bind) = $q->select(
    -columns => ['*'],
    -from    => [
      'users|u',
      $q->left_join('orders|o', {
        'u.id'     => $q->col('o.user_id'),
        'o.status' => 'completed',
      }),
    ],
  )->to_sql;
  like $sql, qr/LEFT JOIN orders o ON/, 'hashref ON';
  like $sql, qr/o\.status = \?/, 'hashref ON equality';
  like $sql, qr/u\.id = o\.user_id/, 'hashref ON col ref';
  is_deeply \@bind, ['completed'], 'hashref ON binds';
}

# join on subquery
{
  my $sub = $q->select(
    -columns  => ['user_id', $q->func('MAX', 'login_date')->as('last_login')],
    -from     => 'logins',
    -group_by => 'user_id',
  )->as('ll');
  my ($sql, @bind) = $q->select(
    -columns => ['u.name', 'll.last_login'],
    -from    => ['users|u', $q->join($sub, 'u.id = ll.user_id')],
  )->to_sql;
  like $sql, qr/JOIN \(SELECT user_id, MAX\(login_date\) AS last_login FROM logins GROUP BY user_id\) AS ll ON u\.id = ll\.user_id/, 'subquery join';
}

done_testing;
