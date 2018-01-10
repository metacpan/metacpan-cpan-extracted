use strict;
use warnings;
no warnings qw/qw/;
use Test::More;

use SQL::Abstract::More;
use SQL::Abstract::Test import => ['is_same_sql_bind'];


my $sqla  = SQL::Abstract::More->new(
  join_with_USING => 1,
 );
my $join;

# basic join
$join = $sqla->join(qw[Foo {A=A} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar USING (A)",
  [],
  "basic",
);

# with explicit table names
$join = $sqla->join(qw[Foo {Foo.A=Bar.A} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar USING (A)",
  [],
  "explicit table name",
);

# condition on two columns
$join = $sqla->join(qw[Foo {Foo.A=Bar.A,B=B} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar USING (B,A)",
  [],
  "cond on 2 cols",
);

# condition with different column names -- no USING clause
$join = $sqla->join(qw[Foo {Foo.A=Bar.A,B=B,C=D} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON  Foo.B=Bar.B AND Foo.C=Bar.D AND Foo.A=Bar.A",
  [],
  "different column names",
);


# inequality operator -- no USING clause
$join = $sqla->join(qw[Foo {Foo.A>Bar.A} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON Foo.A > Bar.A",
  [],
  "inequality operator",
);


# several tables
$join = $sqla->join(qw[Foo {A=A} Bar {B=B} Buz]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar USING (A) INNER JOIN Buz USING (B)",
  [],
  "several tables",
);



done_testing;
