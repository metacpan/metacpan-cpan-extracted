use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# col + col
{
  my $expr = $q->col('price') + $q->col('tax');
  isa_ok $expr, 'SQL::Wizard::Expr::BinaryOp';
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'price + tax', 'col + col';
  is_deeply \@bind, [], 'no binds';
}

# col * val
{
  my $expr = $q->col('price') * $q->val(0.2);
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'price * ?', 'col * val';
  is_deeply \@bind, [0.2], 'val bind';
}

# col - plain number (auto-coerce)
{
  my $expr = $q->col('score') - 10;
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'score - ?', 'col - number';
  is_deeply \@bind, [10], 'number coerced to val';
}

# col / col
{
  my $expr = $q->col('total') / $q->col('count');
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'total / count', 'col / col';
}

# col % val
{
  my $expr = $q->col('id') % 2;
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'id % ?', 'col % val';
  is_deeply \@bind, [2], 'modulo bind';
}

# chained: (price * qty) + tax
{
  my $subtotal = $q->col('price') * $q->col('qty');
  my $total    = $subtotal + $q->col('tax');
  my ($sql, @bind) = $total->to_sql;
  is $sql, 'price * qty + tax', 'chained arithmetic';
}

# func in arithmetic: SUM(amount) / COUNT(*)
{
  my $avg = $q->func('SUM', 'amount') / $q->func('COUNT', '*');
  my ($sql, @bind) = $avg->to_sql;
  is $sql, 'SUM(amount) / COUNT(*)', 'func in arithmetic';
}

# with alias
{
  my $expr = ($q->col('price') * $q->col('qty'))->as('subtotal');
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'price * qty AS subtotal', 'arithmetic with alias';
}

# in select context
{
  my $total = $q->col('price') * $q->col('qty');
  my $tax   = $total * $q->val(0.2);
  my $sel = $q->select(
    -columns => [$total->as('subtotal'), $tax->as('tax')],
    -from    => 'line_items',
  );
  my ($sql, @bind) = $sel->to_sql;
  is $sql, 'SELECT price * qty AS subtotal, price * qty * ? AS tax FROM line_items',
    'arithmetic in select';
  is_deeply \@bind, [0.2], 'arithmetic select binds';
}

# swapped operand: number + col
{
  my $expr = 100 + $q->col('bonus');
  my ($sql, @bind) = $expr->to_sql;
  is $sql, '? + bonus', 'swapped: number + col';
  is_deeply \@bind, [100], 'swapped bind';
}

done_testing;
