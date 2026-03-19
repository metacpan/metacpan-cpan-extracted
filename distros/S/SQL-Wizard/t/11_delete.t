use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# simple delete
{
  my ($sql, @bind) = $q->delete(
    -from  => 'users',
    -where => { status => 'deleted' },
  )->to_sql;
  is $sql, 'DELETE FROM users WHERE status = ?', 'simple delete';
  is_deeply \@bind, ['deleted'], 'delete binds';
}

# delete with multiple conditions
{
  my ($sql, @bind) = $q->delete(
    -from  => 'users',
    -where => { status => 'deleted', last_login => { '<' => '2020-01-01' } },
  )->to_sql;
  like $sql, qr/DELETE FROM users WHERE/, 'delete multi where';
  like $sql, qr/last_login < \?/, 'delete operator condition';
  like $sql, qr/status = \?/, 'delete equality condition';
  is_deeply \@bind, ['2020-01-01', 'deleted'], 'delete multi binds';
}

# delete with subquery
{
  my $sub = $q->select(-columns => ['user_id'], -from => 'active_sessions');
  my ($sql, @bind) = $q->delete(
    -from  => 'users',
    -where => { id => { -not_in => $sub } },
  )->to_sql;
  like $sql, qr/DELETE FROM users WHERE id NOT IN \(SELECT user_id FROM active_sessions\)/, 'delete subquery';
}

# delete with USING (PostgreSQL)
{
  my ($sql, @bind) = $q->delete(
    -from  => 'orders',
    -using => 'users',
    -where => {
      'orders.user_id' => $q->col('users.id'),
      'users.status'   => 'banned',
    },
  )->to_sql;
  like $sql, qr/DELETE FROM orders USING users/, 'delete using';
  like $sql, qr/orders\.user_id = users\.id/, 'using join condition';
  like $sql, qr/users\.status = \?/, 'using where';
  is_deeply \@bind, ['banned'], 'delete using binds';
}

# DELETE with RETURNING
{
  my ($sql, @bind) = $q->delete(
    -from      => 'users',
    -where     => { status => 'deleted' },
    -returning => ['id', 'email'],
  )->to_sql;
  like $sql, qr/RETURNING id, email$/, 'delete returning';
}

# delete without where
{
  my ($sql, @bind) = $q->delete(-from => 'temp_table')->to_sql;
  is $sql, 'DELETE FROM temp_table', 'delete no where';
  is_deeply \@bind, [], 'delete no where no binds';
}

done_testing;
