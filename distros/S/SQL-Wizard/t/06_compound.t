use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# UNION
{
  my $a = $q->select(-columns => [qw/id name/], -from => 'active_users');
  my $b = $q->select(-columns => [qw/id name/], -from => 'legacy_users');
  my ($sql, @bind) = $a->union($b)->to_sql;
  is $sql, '(SELECT id, name FROM active_users) UNION (SELECT id, name FROM legacy_users)', 'union';
}

# UNION ALL
{
  my $a = $q->select(-columns => ['*'], -from => 'table_a');
  my $b = $q->select(-columns => ['*'], -from => 'table_b');
  my ($sql, @bind) = $a->union_all($b)->to_sql;
  is $sql, '(SELECT * FROM table_a) UNION ALL (SELECT * FROM table_b)', 'union all';
}

# INTERSECT
{
  my $a = $q->select(-columns => ['id'], -from => 'set_a');
  my $b = $q->select(-columns => ['id'], -from => 'set_b');
  my ($sql, @bind) = $a->intersect($b)->to_sql;
  is $sql, '(SELECT id FROM set_a) INTERSECT (SELECT id FROM set_b)', 'intersect';
}

# EXCEPT
{
  my $a = $q->select(-columns => ['id'], -from => 'all_users');
  my $b = $q->select(-columns => ['id'], -from => 'banned_users');
  my ($sql, @bind) = $a->except($b)->to_sql;
  is $sql, '(SELECT id FROM all_users) EXCEPT (SELECT id FROM banned_users)', 'except';
}

# chained compounds
{
  my $a = $q->select(-columns => [qw/id name/], -from => 'active_users');
  my $b = $q->select(-columns => [qw/id name/], -from => 'legacy_users');
  my $c = $q->select(-columns => [qw/id name/], -from => 'pending_users');
  my ($sql, @bind) = $a->union($b)->union_all($c)->to_sql;
  is $sql,
    '(SELECT id, name FROM active_users) UNION (SELECT id, name FROM legacy_users) UNION ALL (SELECT id, name FROM pending_users)',
    'chained compounds';
}

# compound with order_by / limit / offset
{
  my $a = $q->select(-columns => [qw/id name/], -from => 'active_users');
  my $b = $q->select(-columns => [qw/id name/], -from => 'legacy_users');
  my ($sql, @bind) = $a->union($b)->order_by('name')->limit(100)->to_sql;
  like $sql, qr/UNION/, 'compound has union';
  like $sql, qr/ORDER BY name/, 'compound has order';
  like $sql, qr/LIMIT \?/, 'compound has limit';
  is $bind[-1], 100, 'compound limit bind';
}

# compound with binds
{
  my $a = $q->select(-from => 'users', -where => { status => 'active' });
  my $b = $q->select(-from => 'users', -where => { status => 'pending' });
  my ($sql, @bind) = $a->union($b)->to_sql;
  is_deeply \@bind, ['active', 'pending'], 'compound binds collected';
}

# compound immutability
{
  my $a = $q->select(-columns => ['id'], -from => 'a');
  my $b = $q->select(-columns => ['id'], -from => 'b');
  my $c = $q->select(-columns => ['id'], -from => 'c');
  my $ab = $a->union($b);
  my $abc = $ab->union_all($c);
  my ($ab_sql)  = $ab->to_sql;
  my ($abc_sql) = $abc->to_sql;
  unlike $ab_sql, qr/UNION ALL/, 'original compound unchanged';
  like $abc_sql, qr/UNION ALL/, 'extended compound has new entry';
}

done_testing;
