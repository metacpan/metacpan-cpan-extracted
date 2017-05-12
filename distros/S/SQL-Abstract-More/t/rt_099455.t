use strict;
use warnings;
use Test::More;
use Test::Exception;

use SQL::Abstract::More;
use SQL::Abstract::Test import => ['is_same_sql_bind'];

# GOAL : spaces before the column spec or after the alias name will be ignored

plan tests => 1;

my $sqla = SQL::Abstract::More->new();

my ($sql,@bind) = $sqla->select(
  -from    => 'foo',
  -columns => q[ concat_ws( ' ', t2.first_name,t2.last_name )|assigned_by_long ],
);

is_same_sql_bind (
  $sql, \@bind,
  q[SELECT concat_ws( ' ', t2.first_name,t2.last_name ) AS assigned_by_long FROM foo],
  [],
);
