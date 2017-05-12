use strict;
use warnings;
no warnings qw/qw/;
use Test::More;

use SQL::Abstract::More;
use SQL::Abstract::Test import => ['is_same_sql_bind'];

my ($sql, @bind);

# test multicols with SQL support
my $sqla  = SQL::Abstract::More->new(
#  multicols_sep        => '/',
  multicols_sep        => qr[\s*/\s*],
  has_multicols_in_SQL => 1,
);

($sql, @bind) = $sqla->where({
  one_col   => 999,
  "foo/bar" => {-in     => ["1/a", "2/b"]},
  "x/y/z"   => {-not_in => ["X/Y/Z"]},
});
my @expected = ("WHERE (foo, bar) IN ((?, ?), (?, ?)) "
                 ."AND one_col = ? "
                 ."AND (x, y, z) NOT IN ((?, ?, ?))",
                [qw/1 a 2 b 999 X Y Z/]);
is_same_sql_bind($sql, \@bind, @expected);

# same test, but with values passed as arrayrefs
($sql, @bind) = $sqla->where({
  one_col   => 999,
  "foo/bar" => {-in     => [[1, "a"], [2, "b"]]},
  "x/y/z"   => {-not_in => [[qw/X Y Z/]]},
});
is_same_sql_bind($sql, \@bind, @expected);

# right-hand side as a subquery
($sql, @bind) = $sqla->where({
  one_col   => 999,
  "foo/bar" => {-in  => \"SELECT (a, b) FROM FOOBAR"},
});
is_same_sql_bind($sql, \@bind, 
                 "WHERE (foo, bar) IN (SELECT (a, b) FROM FOOBAR)"
                 ."AND one_col = ? ",
                 [999]);

# right-hand side as a subquery with bind values
($sql, @bind) = $sqla->where({
  one_col   => 999,
  "foo/bar" => {-in  => \["SELECT (a, b) FROM FOOBAR WHERE a > ?", 1234]},
});
is_same_sql_bind($sql, \@bind, 
                 "WHERE (foo, bar) IN (SELECT (a, b) FROM FOOBAR WHERE a > ?)"
                 ."AND one_col = ? ",
                 [1234, 999]);



# test multicols without SQL support
$sqla  = SQL::Abstract::More->new(
#  multicols_sep        => '/',
  multicols_sep        => qr[\s*/\s*],
  has_multicols_in_SQL => 0,
);

($sql, @bind) = $sqla->where({
  one_col   => 999,
  "foo/bar" => {-in     => ["1/a", "2/b"]},
  "x/y/z"   => {-not_in => ["X/Y/Z"]},
});
is_same_sql_bind(
  $sql, \@bind,
  "WHERE ((foo = ? AND bar = ?) OR (foo = ? AND bar = ?)) "
   ."AND one_col = ? "
   ."AND NOT (x = ? AND y = ? AND z = ?)",
  [qw/1 a 2 b 999 X Y Z/],
);


done_testing();

