use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

sub where_sql {
  my ($where) = @_;
  $q->select(-from => 'x', -where => $where)->to_sql;
}

# simple equality
{
  my ($sql, @bind) = where_sql({ name => 'alice' });
  like $sql, qr/WHERE name = \?/, 'simple equality';
  is_deeply \@bind, ['alice'], 'equality bind';
}

# multiple keys (AND)
{
  my ($sql, @bind) = where_sql({ age => 25, name => 'bob' });
  like $sql, qr/WHERE age = \? AND name = \?/, 'multi key AND';
  is_deeply \@bind, [25, 'bob'], 'multi key binds';
}

# IS NULL
{
  my ($sql, @bind) = where_sql({ parent_id => undef });
  like $sql, qr/WHERE parent_id IS NULL/, 'IS NULL';
  is_deeply \@bind, [], 'null no binds';
}

# IS NOT NULL via != undef
{
  my ($sql, @bind) = where_sql({ deleted_at => { '!=' => undef } });
  like $sql, qr/WHERE deleted_at IS NOT NULL/, 'IS NOT NULL via !=';
  is_deeply \@bind, [], 'IS NOT NULL no binds';
}

# IS NOT NULL via <> undef
{
  my ($sql, @bind) = where_sql({ deleted_at => { '<>' => undef } });
  like $sql, qr/WHERE deleted_at IS NOT NULL/, 'IS NOT NULL via <>';
  is_deeply \@bind, [], 'IS NOT NULL <> no binds';
}

# IS NULL via = undef in operator form
{
  my ($sql, @bind) = where_sql({ deleted_at => { '=' => undef } });
  like $sql, qr/WHERE deleted_at IS NULL/, 'IS NULL via = undef';
  is_deeply \@bind, [], 'IS NULL = no binds';
}

# operator: >
{
  my ($sql, @bind) = where_sql({ age => { '>' => 18 } });
  like $sql, qr/WHERE age > \?/, 'operator >';
  is_deeply \@bind, [18], 'operator bind';
}

# operator: >=, <, <=, !=
{
  my ($sql, @bind) = where_sql({ age => { '>=' => 18 } });
  like $sql, qr/WHERE age >= \?/, '>= operator';
}
{
  my ($sql, @bind) = where_sql({ age => { '<' => 65 } });
  like $sql, qr/WHERE age < \?/, '< operator';
}
{
  my ($sql, @bind) = where_sql({ age => { '!=' => 0 } });
  like $sql, qr/WHERE age != \?/, '!= operator';
}

# -in
{
  my ($sql, @bind) = where_sql({ country => { -in => ['FR', 'DE', 'IT'] } });
  like $sql, qr/WHERE country IN \(\?, \?, \?\)/, '-in';
  is_deeply \@bind, ['FR', 'DE', 'IT'], '-in binds';
}

# -not_in
{
  my ($sql, @bind) = where_sql({ status => { -not_in => ['banned', 'deleted'] } });
  like $sql, qr/WHERE status NOT IN \(\?, \?\)/, '-not_in';
  is_deeply \@bind, ['banned', 'deleted'], '-not_in binds';
}

# empty -in list => always false
{
  my ($sql, @bind) = where_sql({ id => { -in => [] } });
  like $sql, qr/WHERE 1 = 0/, 'empty -in is always false';
  is_deeply \@bind, [], 'empty -in no binds';
}

# empty -not_in list => always true
{
  my ($sql, @bind) = where_sql({ id => { -not_in => [] } });
  like $sql, qr/WHERE 1 = 1/, 'empty -not_in is always true';
  is_deeply \@bind, [], 'empty -not_in no binds';
}

# empty arrayref value => always false
{
  my ($sql, @bind) = where_sql({ id => [] });
  like $sql, qr/WHERE 1 = 0/, 'empty array value is always false';
  is_deeply \@bind, [], 'empty array value no binds';
}

# -in with subquery
{
  my $sub = $q->select(-columns => ['user_id'], -from => 'orders');
  my ($sql, @bind) = where_sql({ id => { -in => $sub } });
  like $sql, qr/WHERE id IN \(SELECT user_id FROM orders\)/, '-in subquery';
}

# array value = IN
{
  my ($sql, @bind) = where_sql({ id => [1, 2, 3] });
  like $sql, qr/WHERE id IN \(\?, \?, \?\)/, 'array value as IN';
  is_deeply \@bind, [1, 2, 3], 'array value binds';
}

# -and array
{
  my ($sql, @bind) = where_sql([
    -and => [
      { status => 'active' },
      { age => { '>' => 18 } },
    ],
  ]);
  like $sql, qr/WHERE.*status = \?.*AND.*age > \?/, '-and array';
  is_deeply \@bind, ['active', 18], '-and binds';
}

# -or array
{
  my ($sql, @bind) = where_sql([
    -or => [
      { status => 'active' },
      { status => 'pending' },
    ],
  ]);
  like $sql, qr/WHERE.*status = \?.*OR.*status = \?/, '-or array';
  is_deeply \@bind, ['active', 'pending'], '-or binds';
}

# nested -and/-or
{
  my ($sql, @bind) = where_sql([
    -and => [
      { status => 'active' },
      [-or => [
        { role => 'admin' },
        { role => 'editor' },
      ]],
    ],
  ]);
  like $sql, qr/status = \?.*AND.*\(role = \? OR role = \?\)/, 'nested and/or';
  is_deeply \@bind, ['active', 'admin', 'editor'], 'nested binds';
}

# Expr object as value
{
  my ($sql, @bind) = where_sql({ user_id => $q->col('u.id') });
  like $sql, qr/WHERE user_id = u\.id/, 'expr as value';
  is_deeply \@bind, [], 'expr no binds';
}

# plain string where
{
  my ($sql, @bind) = where_sql('1 = 1');
  like $sql, qr/WHERE 1 = 1/, 'string where';
  is_deeply \@bind, [], 'string where no binds';
}

# all valid operators (lowercase input → uppercase SQL)
{
  my %expect = (
    '='        => 'x = ?',
    '!='       => 'x != ?',
    '<>'       => 'x <> ?',
    '<'        => 'x < ?',
    '>'        => 'x > ?',
    '<='       => 'x <= ?',
    '>='       => 'x >= ?',
    'like'     => 'x LIKE ?',
    'LIKE'     => 'x LIKE ?',
    'not like' => 'x NOT LIKE ?',
    'NOT LIKE' => 'x NOT LIKE ?',
    'ilike'    => 'x ILIKE ?',
    'ILIKE'    => 'x ILIKE ?',
    'not ilike' => 'x NOT ILIKE ?',
    'NOT ILIKE' => 'x NOT ILIKE ?',
  );
  for my $op (sort keys %expect) {
    my ($sql, @bind) = where_sql({ x => { $op => 42 } });
    like $sql, qr/\Q$expect{$op}\E/, "operator '$op' renders as '$expect{$op}'";
    is_deeply \@bind, [42], "operator '$op' bind";
  }

  # -in / -not_in (special syntax)
  {
    my ($sql, @bind) = where_sql({ x => { -in => [1, 2] } });
    like $sql, qr/x IN \(\?, \?\)/, 'operator -in';
    is_deeply \@bind, [1, 2], '-in binds';
  }
  {
    my ($sql, @bind) = where_sql({ x => { -not_in => [3, 4] } });
    like $sql, qr/x NOT IN \(\?, \?\)/, 'operator -not_in';
    is_deeply \@bind, [3, 4], '-not_in binds';
  }

  # unknown operator → confess
  eval { where_sql({ x => { 'BADOP' => 1 } }) };
  like $@, qr/Unknown operator 'BADOP'/, 'bad operator rejected';
}

# empty where clause omitted
{
  my ($sql, @bind) = where_sql({});
  unlike $sql, qr/WHERE/, 'empty hashref where omitted';
}
{
  my ($sql, @bind) = where_sql([]);
  unlike $sql, qr/WHERE/, 'empty arrayref where omitted';
}

done_testing;
