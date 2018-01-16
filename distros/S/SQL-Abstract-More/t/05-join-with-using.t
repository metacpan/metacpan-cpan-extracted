use strict;
use warnings;
no warnings qw/qw/;
use Test::More;

use SQL::Abstract::More;
use SQL::Abstract::Test import => ['is_same_sql_bind'];


my $sqla  = SQL::Abstract::More->new;
my $join;

# basic join
$join = $sqla->join(qw[Foo {A} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar USING (A)",
  [],
  "basic",
);

# condition on two columns
$join = $sqla->join(qw[Foo {A,B} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar USING (A,B)",
  [],
  "cond on 2 cols",
);


# several tables
$join = $sqla->join(qw[Foo {A} Bar {B} Buz]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar USING (A) INNER JOIN Buz USING (B)",
  [],
  "several tables",
);



$join = $sqla->join('Foo', {operator => '=>',
                            using    => [qw/A B/]}, 'Bar');
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo LEFT OUTER JOIN Bar USING (A, B)",
  [],
  "structured join spec",
);


eval {
  $join = $sqla->join('Foo', {operator  => '=>',
                              using     => [qw/A/],
                              condition => {"Foo.A" => {-ident => "Bar.A"}}},
                      'Bar');
};
my $err = $@;
like $err, qr/both.*condition.*using/, "proper error message";


done_testing;
