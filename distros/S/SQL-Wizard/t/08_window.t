use strict;
use warnings;
use Test::More;
use SQL::Wizard;

my $q = SQL::Wizard->new;

# ROW_NUMBER with inline window spec
{
  my $expr = $q->func('ROW_NUMBER')->over(
    -partition_by => 'department',
    -order_by     => [{ -desc => 'salary' }],
  )->as('rank');
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rank', 'row_number';
}

# SUM with frame
{
  my $expr = $q->func('SUM', 'amount')->over(
    -partition_by => 'account_id',
    -order_by     => 'transaction_date',
    -frame        => 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW',
  )->as('running_total');
  my ($sql, @bind) = $expr->to_sql;
  like $sql, qr/SUM\(amount\) OVER \(PARTITION BY account_id ORDER BY transaction_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW\) AS running_total/, 'running total';
}

# LAG
{
  my $expr = $q->func('LAG', 'salary', $q->val(1))->over(
    -partition_by => 'department',
    -order_by     => 'hire_date',
  )->as('prev_salary');
  my ($sql, @bind) = $expr->to_sql;
  like $sql, qr/LAG\(salary, \?\) OVER \(PARTITION BY department ORDER BY hire_date\) AS prev_salary/, 'lag';
  is_deeply \@bind, [1], 'lag bind';
}

# named window
{
  my $expr = $q->func('RANK')->over('dept_window')->as('dept_rank');
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'RANK() OVER dept_window AS dept_rank', 'named window';
}

# named window in select with WINDOW clause
{
  my ($sql, @bind) = $q->select(
    -columns => [
      'name',
      'department',
      'salary',
      $q->func('RANK')->over('w')->as('dept_rank'),
      $q->func('DENSE_RANK')->over('w')->as('dept_dense_rank'),
    ],
    -from   => 'employees',
    -window => {
      w => {
        '-partition_by' => 'department',
        '-order_by'     => [{ -desc => 'salary' }],
      },
    },
  )->to_sql;
  like $sql, qr/RANK\(\) OVER w AS dept_rank/, 'rank over named window';
  like $sql, qr/DENSE_RANK\(\) OVER w AS dept_dense_rank/, 'dense_rank over named window';
  like $sql, qr/WINDOW w AS \(PARTITION BY department ORDER BY salary DESC\)/, 'window clause';
}

# over with order_by only (no partition)
{
  my $expr = $q->func('ROW_NUMBER')->over(
    -order_by => 'id',
  )->as('rn');
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'ROW_NUMBER() OVER (ORDER BY id) AS rn', 'order only window';
}

# multiple partition_by columns
{
  my $expr = $q->func('SUM', 'amount')->over(
    -partition_by => ['department', 'year'],
    -order_by     => 'month',
  );
  my ($sql, @bind) = $expr->to_sql;
  is $sql, 'SUM(amount) OVER (PARTITION BY department, year ORDER BY month)', 'multi partition';
}

done_testing;
