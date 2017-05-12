use strict;
use warnings;
use Test::More;
use Test::Exception;

use SQL::Abstract::More;
use SQL::Abstract::Test import => ['is_same_sql_bind'];

plan tests => 2;

my $sqla = SQL::Abstract::More->new();

my ($sql,@bind) = $sqla->select(
  -from => 't2',
  -where => {col => {-in => \[$sqla->select(
    -columns   => 'some_key',
    -from      => 't1',
    -order_by  => 'foo',
   )]}},
  -group_by => 'bar',
);

is_same_sql_bind (
  $sql,
  \@bind,
  'SELECT * FROM t2 WHERE ( col IN ( SELECT some_key FROM t1  ORDER BY foo ) ) '
         . 'GROUP BY bar',
  [],
);


($sql,@bind) = $sqla->select(
  -from => 't2',
  -where => {col => {-in => \[$sqla->select(
    -columns   => 'some_key',
    -from      => 't1',
    -order_by  => 'foo',
   )]}},
  -group_by => 'bar',
  -order_by => 'buz',
);


is_same_sql_bind (
  $sql,
  \@bind,
  'SELECT * FROM t2 WHERE ( col IN ( SELECT some_key FROM t1  ORDER BY foo ) ) '
         . 'GROUP BY bar ORDER BY buz',
  [],
);

