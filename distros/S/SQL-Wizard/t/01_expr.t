use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# col()
{
  my $c = $q->col('u.name');
  isa_ok $c, 'SQL::Wizard::Expr::Column';
  my ($sql, @bind) = $c->to_sql;
  is $sql, 'u.name', 'col renders name';
  is_deeply \@bind, [], 'col has no binds';
}

# val()
{
  my $v = $q->val(42);
  isa_ok $v, 'SQL::Wizard::Expr::Value';
  my ($sql, @bind) = $v->to_sql;
  is $sql, '?', 'val renders placeholder';
  is_deeply \@bind, [42], 'val has bind';
}

# raw() without binds
{
  my $r = $q->raw('NOW()');
  isa_ok $r, 'SQL::Wizard::Expr::Raw';
  my ($sql, @bind) = $r->to_sql;
  is $sql, 'NOW()', 'raw renders sql';
  is_deeply \@bind, [], 'raw no binds';
}

# raw() with binds
{
  my $r = $q->raw('? + ?', 1, 2);
  my ($sql, @bind) = $r->to_sql;
  is $sql, '? + ?', 'raw with binds sql';
  is_deeply \@bind, [1, 2], 'raw with binds';
}

# func()
{
  my $f = $q->func('COUNT', '*');
  isa_ok $f, 'SQL::Wizard::Expr::Func';
  my ($sql, @bind) = $f->to_sql;
  is $sql, 'COUNT(*)', 'func renders';
  is_deeply \@bind, [], 'func no binds';
}

# func with multiple args
{
  my $f = $q->func('COALESCE', 'u.nickname', $q->val('Anonymous'));
  my ($sql, @bind) = $f->to_sql;
  is $sql, 'COALESCE(u.nickname, ?)', 'func multi args';
  is_deeply \@bind, ['Anonymous'], 'func multi args binds';
}

# func with no args
{
  my $f = $q->func('NOW');
  my ($sql, @bind) = $f->to_sql;
  is $sql, 'NOW()', 'func no args';
}

# as()
{
  my $c = $q->col('u.name')->as('user_name');
  isa_ok $c, 'SQL::Wizard::Expr::Alias';
  my ($sql, @bind) = $c->to_sql;
  is $sql, 'u.name AS user_name', 'as renders alias';
}

# func with as
{
  my $f = $q->func('COUNT', '*')->as('total');
  my ($sql, @bind) = $f->to_sql;
  is $sql, 'COUNT(*) AS total', 'func as alias';
}

# asc / desc
{
  my ($sql, @bind) = $q->col('name')->asc->to_sql;
  is $sql, 'name ASC', 'asc';
}
{
  my ($sql, @bind) = $q->col('name')->desc->to_sql;
  is $sql, 'name DESC', 'desc';
}

# asc_nulls_first / desc_nulls_last
{
  my ($sql, @bind) = $q->col('score')->asc_nulls_first->to_sql;
  is $sql, 'score ASC NULLS FIRST', 'asc nulls first';
}
{
  my ($sql, @bind) = $q->col('score')->desc_nulls_last->to_sql;
  is $sql, 'score DESC NULLS LAST', 'desc nulls last';
}

# coalesce / greatest / least shortcuts
{
  my ($sql, @bind) = $q->coalesce('a', $q->val(0))->to_sql;
  is $sql, 'COALESCE(a, ?)', 'coalesce shortcut';
  is_deeply \@bind, [0], 'coalesce binds';
}
{
  my ($sql, @bind) = $q->greatest('a', 'b')->to_sql;
  is $sql, 'GREATEST(a, b)', 'greatest shortcut';
}
{
  my ($sql, @bind) = $q->least('a', 'b')->to_sql;
  is $sql, 'LEAST(a, b)', 'least shortcut';
}

# exists
{
  my $sub = $q->select(-columns => [1], -from => 'vip', -where => { user_id => 1 });
  my $e = $q->exists($sub);
  my ($sql, @bind) = $e->to_sql;
  is $sql, 'EXISTS(SELECT 1 FROM vip WHERE user_id = ?)', 'exists';
  is_deeply \@bind, [1], 'exists binds';
}

# not_exists
{
  my $sub = $q->select(-columns => [1], -from => 'vip');
  my $e = $q->not_exists($sub);
  my ($sql, @bind) = $e->to_sql;
  is $sql, 'NOT EXISTS(SELECT 1 FROM vip)', 'not_exists';
}

# any
{
  my $sub = $q->select(-columns => ['salary'], -from => 'managers');
  my $e = $q->any($sub);
  my ($sql, @bind) = $e->to_sql;
  is $sql, 'ANY(SELECT salary FROM managers)', 'any';
  is_deeply \@bind, [], 'any no binds';
}

# all
{
  my $sub = $q->select(-columns => ['salary'], -from => 'interns');
  my $e = $q->all($sub);
  my ($sql, @bind) = $e->to_sql;
  is $sql, 'ALL(SELECT salary FROM interns)', 'all';
  is_deeply \@bind, [], 'all no binds';
}

# any/all in WHERE
{
  my $sub = $q->select(-columns => ['salary'], -from => 'managers');
  my ($sql, @bind) = $q->select(
    -from  => 'employees',
    -where => { salary => { '>' => $q->any($sub) } },
  )->to_sql;
  like $sql, qr/WHERE salary > ANY\(SELECT salary FROM managers\)/, 'any in where';
}
{
  my $sub = $q->select(-columns => ['salary'], -from => 'interns');
  my ($sql, @bind) = $q->select(
    -from  => 'employees',
    -where => { salary => { '>' => $q->all($sub) } },
  )->to_sql;
  like $sql, qr/WHERE salary > ALL\(SELECT salary FROM interns\)/, 'all in where';
}

# between
{
  my $b = $q->between('age', 18, 65);
  my ($sql, @bind) = $b->to_sql;
  is $sql, 'age BETWEEN ? AND ?', 'between';
  is_deeply \@bind, [18, 65], 'between binds';
}

# not_between
{
  my $b = $q->not_between('age', 0, 17);
  my ($sql, @bind) = $b->to_sql;
  is $sql, 'age NOT BETWEEN ? AND ?', 'not_between';
  is_deeply \@bind, [0, 17], 'not_between binds';
}

# cast
{
  my $c = $q->cast('price', 'INTEGER');
  my ($sql, @bind) = $c->to_sql;
  is $sql, 'CAST(price AS INTEGER)', 'cast';
  is_deeply \@bind, [], 'cast no binds';
}

# and / or / not
{
  my $a = $q->and({ status => 'active' }, { role => 'admin' });
  my ($sql, @bind) = $a->to_sql;
  is $sql, '(status = ? AND role = ?)', 'and';
  is_deeply \@bind, ['active', 'admin'], 'and binds';
}
{
  my $o = $q->or({ status => 'active' }, { status => 'pending' });
  my ($sql, @bind) = $o->to_sql;
  is $sql, '(status = ? OR status = ?)', 'or';
  is_deeply \@bind, ['active', 'pending'], 'or binds';
}
{
  my $n = $q->not({ status => 'deleted' });
  my ($sql, @bind) = $n->to_sql;
  is $sql, 'NOT (status = ?)', 'not';
  is_deeply \@bind, ['deleted'], 'not binds';
}

done_testing;
