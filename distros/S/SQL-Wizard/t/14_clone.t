use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# base query
my $base = $q->select(
  -columns => ['*'],
  -from    => 'users',
  -where   => { status => 'active' },
);

# add_where returns new object
{
  my $admins = $base->add_where({ role => 'admin' });
  my ($base_sql, @base_bind) = $base->to_sql;
  my ($adm_sql,  @adm_bind)  = $admins->to_sql;
  is $base_sql, 'SELECT * FROM users WHERE status = ?', 'base unchanged after add_where';
  is_deeply \@base_bind, ['active'], 'base binds unchanged';
  like $adm_sql, qr/WHERE.*status = \?.*AND.*role = \?/, 'add_where adds condition';
  is_deeply \@adm_bind, ['active', 'admin'], 'add_where binds';
}

# columns returns new object
{
  my $counted = $base->columns([$q->func('COUNT', '*')->as('total')]);
  my ($base_sql) = $base->to_sql;
  my ($cnt_sql)  = $counted->to_sql;
  is $base_sql, 'SELECT * FROM users WHERE status = ?', 'base unchanged after columns';
  like $cnt_sql, qr/SELECT COUNT\(\*\) AS total FROM users/, 'columns replaced';
}

# order_by returns new object
{
  my $sorted = $base->order_by('name');
  my ($base_sql) = $base->to_sql;
  my ($sort_sql) = $sorted->to_sql;
  unlike $base_sql, qr/ORDER BY/, 'base has no order';
  like $sort_sql, qr/ORDER BY name/, 'sorted has order';
}

# limit returns new object
{
  my $limited = $base->limit(10);
  my ($base_sql) = $base->to_sql;
  my ($lim_sql)  = $limited->to_sql;
  unlike $base_sql, qr/LIMIT/, 'base has no limit';
  like $lim_sql, qr/LIMIT 10/, 'limited has limit';
}

# offset returns new object
{
  my $paged = $base->limit(20)->offset(40);
  my ($base_sql) = $base->to_sql;
  my ($page_sql) = $paged->to_sql;
  unlike $base_sql, qr/OFFSET/, 'base has no offset';
  like $page_sql, qr/LIMIT 20 OFFSET 40/, 'paged has offset';
}

# chaining modifiers
{
  my $result = $base
    ->add_where({ role => 'editor' })
    ->order_by('name')
    ->limit(50)
    ->offset(100);
  my ($sql, @bind) = $result->to_sql;
  like $sql, qr/WHERE/, 'chained has where';
  like $sql, qr/ORDER BY name/, 'chained has order';
  like $sql, qr/LIMIT 50/, 'chained has limit';
  like $sql, qr/OFFSET 100/, 'chained has offset';

  # Original base is still clean
  my ($base_sql) = $base->to_sql;
  is $base_sql, 'SELECT * FROM users WHERE status = ?', 'base still unchanged after chaining';
}

done_testing;
