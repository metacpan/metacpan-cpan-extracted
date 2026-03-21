use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# simple update
{
  my ($sql, @bind) = $q->update(
    -table => 'users',
    -set   => { status => 'inactive', updated_at => $q->now },
    -where => { last_login => { '<' => '2023-01-01' } },
  )->to_sql;
  like $sql, qr/^UPDATE users SET/, 'update start';
  like $sql, qr/status = \?/, 'set status';
  like $sql, qr/updated_at = NOW\(\)/, 'set raw';
  like $sql, qr/WHERE last_login < \?/, 'update where';
  is_deeply \@bind, ['inactive', '2023-01-01'], 'update binds';
}

# update with join (MySQL style)
{
  my ($sql, @bind) = $q->update(
    -table => ['users|u', $q->join('orders|o', 'u.id = o.user_id')],
    -set   => { 'u.last_order' => $q->col('o.created_at') },
    -where => { 'o.status' => 'completed' },
  )->to_sql;
  like $sql, qr/UPDATE users u JOIN orders o ON u\.id = o\.user_id/, 'update with join';
  like $sql, qr/SET u\.last_order = o\.created_at/, 'set from join';
  like $sql, qr/WHERE o\.status = \?/, 'update join where';
  is_deeply \@bind, ['completed'], 'update join binds';
}

# update with FROM (PostgreSQL style)
{
  my $sub = $q->select(
    -columns  => ['user_id', $q->func('AVG', 'points')->as('new_score')],
    -from     => 'scores',
    -group_by => 'user_id',
  )->as('s');
  my ($sql, @bind) = $q->update(
    -table => 'users',
    -set   => { score => $q->col('s.new_score') },
    -from  => [$sub],
    -where => { 'users.id' => $q->col('s.user_id') },
  )->to_sql;
  like $sql, qr/UPDATE users SET score = s\.new_score/, 'update from subquery set';
  like $sql, qr/FROM \(SELECT user_id, AVG\(points\) AS new_score FROM scores GROUP BY user_id\) AS s/, 'update from subquery';
  like $sql, qr/WHERE users\.id = s\.user_id/, 'update from where';
}

# UPDATE with RETURNING
{
  my ($sql, @bind) = $q->update(
    -table     => 'users',
    -set       => { status => 'active' },
    -where     => { id => 42 },
    -returning => ['id', 'status'],
  )->to_sql;
  like $sql, qr/RETURNING id, status$/, 'update returning';
  is_deeply \@bind, ['active', 42], 'update returning binds';
}

# update without where
{
  my ($sql, @bind) = $q->update(
    -table => 'config',
    -set   => { value => 'new' },
  )->to_sql;
  is $sql, 'UPDATE config SET value = ?', 'update no where';
  is_deeply \@bind, ['new'], 'update no where binds';
}

# update with limit (MySQL)
{
  my ($sql, @bind) = $q->update(
    -table => 'users',
    -set   => { status => 'inactive' },
    -where => { role => 'guest' },
    -limit => 100,
  )->to_sql;
  like $sql, qr/LIMIT \?$/, 'update with limit';
  is_deeply \@bind, ['inactive', 'guest', 100], 'update limit binds';
}

done_testing;
