use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# simple CTE
{
  my ($sql, @bind) = $q->with(
    recent_orders => $q->select(
      -columns => ['*'],
      -from    => 'orders',
      -where   => { status => 'recent' },
    ),
  )->select(
    -columns => ['*'],
    -from    => 'recent_orders',
  )->to_sql;
  like $sql, qr/^WITH recent_orders AS \(SELECT \* FROM orders WHERE status = \?\) SELECT \* FROM recent_orders$/, 'simple CTE';
  is_deeply \@bind, ['recent'], 'CTE binds';
}

# multiple CTEs
{
  my ($sql, @bind) = $q->with(
    cte_a => $q->select(-from => 'a'),
    cte_b => $q->select(-from => 'b'),
  )->select(-from => 'cte_a')->to_sql;
  like $sql, qr/WITH cte_a AS \(SELECT \* FROM a\), cte_b AS \(SELECT \* FROM b\)/, 'multiple CTEs';
}

# CTE with join in main query
{
  my ($sql, @bind) = $q->with(
    big_spenders => $q->select(
      -columns  => ['user_id', $q->func('SUM', 'total')->as('spent')],
      -from     => 'orders',
      -group_by => 'user_id',
    ),
  )->select(
    -columns  => ['u.name', 'bs.spent'],
    -from     => ['users|u', $q->join('big_spenders|bs', 'u.id = bs.user_id')],
    -order_by => [{ -desc => 'bs.spent' }],
  )->to_sql;
  like $sql, qr/WITH big_spenders AS/, 'CTE with join';
  like $sql, qr/JOIN big_spenders bs ON u\.id = bs\.user_id/, 'CTE join ref';
  like $sql, qr/ORDER BY bs\.spent DESC/, 'CTE order by';
}

# recursive CTE
{
  my ($sql, @bind) = $q->with_recursive(
    org_tree => {
      '-initial' => $q->select(
        -columns => [qw/id name parent_id/],
        -from    => 'employees',
        -where   => { parent_id => undef },
      ),
      '-recurse' => $q->select(
        -columns => ['e.id', 'e.name', 'e.parent_id'],
        -from    => ['employees|e', $q->join('org_tree|t', 'e.parent_id = t.id')],
      ),
    },
  )->select(
    -columns  => ['*'],
    -from     => 'org_tree',
    -order_by => 'name',
  )->to_sql;
  like $sql, qr/^WITH RECURSIVE/, 'recursive keyword';
  like $sql, qr/org_tree AS \(/, 'recursive CTE name';
  like $sql, qr/WHERE parent_id IS NULL/, 'initial query';
  like $sql, qr/UNION ALL/, 'recursive union all';
  like $sql, qr/JOIN org_tree t ON e\.parent_id = t\.id/, 'recursive join';
}

done_testing;
