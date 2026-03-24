use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# subquery as column
{
  my $sub = $q->select(
    -columns => [$q->func('COUNT', '*')],
    -from    => 'orders',
    -where   => { user_id => $q->col('u.id') },
  )->as('order_count');
  my ($sql, @bind) = $q->select(
    -columns => ['u.name', $sub],
    -from    => 'users|u',
  )->to_sql;
  like $sql, qr/SELECT u\.name, \(SELECT COUNT\(\*\) FROM orders WHERE user_id = u\.id\) AS order_count FROM users u/, 'subquery as column';
  is_deeply \@bind, [], 'subquery column no binds';
}

# subquery in FROM
{
  my $sub = $q->select(
    -columns  => ['name', $q->func('SUM', 'amount')->as('total')],
    -from     => 'transactions',
    -group_by => 'name',
  )->as('sub');
  my ($sql, @bind) = $q->select(
    -columns => ['sub.name', 'sub.total'],
    -from    => [$sub],
    -where   => { 'sub.total' => { '>' => 1000 } },
  )->to_sql;
  like $sql, qr/FROM \(SELECT name, SUM\(amount\) AS total FROM transactions GROUP BY name\) AS sub/, 'subquery in FROM';
  like $sql, qr/WHERE sub\.total > \?/, 'where on subquery';
  is_deeply \@bind, [1000], 'subquery from binds';
}

# subquery in WHERE with -in
{
  my $sub = $q->select(-columns => ['user_id'], -from => 'active_sessions');
  my ($sql, @bind) = $q->select(
    -from  => 'users',
    -where => { id => { -in => $sub } },
  )->to_sql;
  like $sql, qr/WHERE id IN \(SELECT user_id FROM active_sessions\)/, 'subquery in WHERE -in';
}

# subquery in WHERE with -not_in
{
  my $sub = $q->select(-columns => ['user_id'], -from => 'blacklist');
  my ($sql, @bind) = $q->select(
    -from  => 'users',
    -where => { id => { -not_in => $sub } },
  )->to_sql;
  like $sql, qr/WHERE id NOT IN \(SELECT user_id FROM blacklist\)/, 'subquery -not_in';
}

# subquery with scalar comparison
{
  my $sub = $q->select(
    -columns => [$q->func('AVG', 'salary')],
    -from    => 'employees',
  );
  my ($sql, @bind) = $q->select(
    -from  => 'employees',
    -where => { salary => { '>' => $sub } },
  )->to_sql;
  like $sql, qr/WHERE salary > \(SELECT AVG\(salary\) FROM employees\)/, 'scalar subquery comparison';
}

# EXISTS in WHERE
{
  my $sub = $q->select(
    -columns => [1],
    -from    => 'vip',
    -where   => { 'vip.user_id' => $q->col('u.id') },
  );
  my ($sql, @bind) = $q->select(
    -columns => ['u.name'],
    -from    => 'users|u',
    -where   => [$q->exists($sub)],
  )->to_sql;
  like $sql, qr/WHERE EXISTS\(SELECT 1 FROM vip WHERE vip\.user_id = u\.id\)/, 'EXISTS in where';
}

# compare: correlated subquery >= value
{
  my $sub = $q->select(
    -columns => [$q->func('COUNT', '*')],
    -from    => 'orders|o',
    -where   => { 'o.user_id' => $q->col('u.id') },
  );
  my ($sql, @bind) = $q->select(
    -columns => [$q->func('COUNT', '*')],
    -from    => 'users|u',
    -where   => [$q->compare($sub, '>=', 5)],
  )->to_sql;
  like $sql, qr/\(SELECT COUNT\(\*\) FROM orders o WHERE o\.user_id = u\.id\) >= \?/, 'compare subquery >= value';
  is_deeply \@bind, [5], 'compare subquery binds';
}

# compare: correlated subquery = value
{
  my $sub = $q->select(
    -columns => [$q->func('COUNT', '*')],
    -from    => 'books|b',
    -where   => { 'b.author_id' => $q->col('a.id') },
  );
  my ($sql, @bind) = $q->select(
    -from  => 'authors|a',
    -where => [$q->compare($sub, '=', 0)],
  )->to_sql;
  like $sql, qr/\(SELECT COUNT\(\*\) FROM books b WHERE b\.author_id = a\.id\) = \?/, 'compare subquery = value';
  is_deeply \@bind, [0], 'compare subquery = binds';
}

# compare: col vs col
{
  my ($sql, @bind) = $q->select(
    -from  => 'orders',
    -where => [$q->compare('total', '>', $q->col('min_total'))],
  )->to_sql;
  like $sql, qr/WHERE total > min_total/, 'compare col > col';
  is_deeply \@bind, [], 'compare col vs col no binds';
}

# compare: col vs value
{
  my ($sql, @bind) = $q->select(
    -from  => 'users',
    -where => [$q->compare('age', '>=', 18)],
  )->to_sql;
  like $sql, qr/WHERE age >= \?/, 'compare col >= value';
  is_deeply \@bind, [18], 'compare col >= value binds';
}

done_testing;
