use strict;
use warnings;
no warnings qw/qw/;
use Test::More;

use SQL::Abstract::More;
use SQL::Abstract::Test import => ['is_same_sql_bind'];


plan tests => 5;

my $sqla  = SQL::Abstract::More->new;
my ($sql, @bind, $join);


$join = $sqla->join(qw[Foo {fk_A=pk_A,B<'toto',C='123'} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON Foo.B < ? AND Foo.C = ? AND Foo.fk_A = Bar.pk_A",
  ['toto', 123],
);


$join = $sqla->join(qw[Foo {fk_A=pk_A,B<'to''to'''} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON Foo.B < ? AND Foo.fk_A = Bar.pk_A",
  ["to'to'"],
);


$join = $sqla->join(qw[Foo {fk_A=pk_A,B<'to<to'} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON Foo.B < ? AND Foo.fk_A = Bar.pk_A",
  ['to<to'],
);


$join = $sqla->join(qw[Foo {fk_A=pk_A,B<'to,to'} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON Foo.B < ? AND Foo.fk_A = Bar.pk_A",
  ['to,to'],
);



$join = $sqla->join(qw[Foo {fk_A=pk_A,B<'to{[}]to'} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON Foo.B < ? AND Foo.fk_A = Bar.pk_A",
  ['to{[}]to'],
);
