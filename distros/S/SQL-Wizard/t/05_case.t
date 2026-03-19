use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# searched CASE
{
  my $expr = $q->case(
    [$q->when({ status => 'active' }, 'Active')],
    [$q->when({ status => 'banned' }, 'Banned')],
    $q->else('Unknown'),
  );
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'CASE WHEN status = ? THEN ? WHEN status = ? THEN ? ELSE ? END', 'searched case';
  is_deeply \@bind, ['active', 'Active', 'banned', 'Banned', 'Unknown'], 'searched case binds';
}

# searched CASE without else
{
  my $expr = $q->case(
    [$q->when({ age => { '>' => 65 } }, 'Senior')],
    [$q->when({ age => { '>' => 18 } }, 'Adult')],
  );
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'CASE WHEN age > ? THEN ? WHEN age > ? THEN ? END', 'case without else';
  is_deeply \@bind, [65, 'Senior', 18, 'Adult'], 'case without else binds';
}

# CASE ON (simple case)
{
  my $expr = $q->case_on(
    $q->col('u.role'),
    [$q->when($q->val('admin'), 'Full Access')],
    [$q->when($q->val('editor'), 'Edit Access')],
    $q->else('Read Only'),
  );
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'CASE u.role WHEN ? THEN ? WHEN ? THEN ? ELSE ? END', 'case on';
  is_deeply \@bind, ['admin', 'Full Access', 'editor', 'Edit Access', 'Read Only'], 'case on binds';
}

# CASE with alias
{
  my $expr = $q->case(
    [$q->when({ status => 'active' }, 'Yes')],
    $q->else('No'),
  )->as('is_active');
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'CASE WHEN status = ? THEN ? ELSE ? END AS is_active', 'case with alias';
  is_deeply \@bind, ['active', 'Yes', 'No'], 'case alias binds';
}

# CASE in select
{
  my ($sql, @bind) = $q->select(
    -columns => [
      'u.name',
      $q->case(
        [$q->when({ status => 'active' }, 'Active')],
        $q->else('Inactive'),
      )->as('status_label'),
    ],
    -from => 'users|u',
  )->to_sql;
  like $sql, qr/SELECT u\.name, CASE WHEN status = \? THEN \? ELSE \? END AS status_label FROM users u/, 'case in select';
  is_deeply \@bind, ['active', 'Active', 'Inactive'], 'case in select binds';
}

# CASE with expr then values
{
  my $expr = $q->case(
    [$q->when({ tier => 'gold' }, $q->col('price') * $q->val(0.9))],
    $q->else($q->col('price')),
  );
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'CASE WHEN tier = ? THEN price * ? ELSE price END', 'case with expr then';
  is_deeply \@bind, ['gold', 0.9], 'case expr then binds';
}

done_testing;
