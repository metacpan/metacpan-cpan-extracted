use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 4;

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT material, diameter
  FROM   grown_wafers
  WHERE diameter = ?
  GROUP BY material
  ORDER BY material, diameter

input type: bogus

input: will_fail

query parameter: $input->{will_fail}

delete column one

no output

no Querylet;

ok(1, "made it here alive");
is( @{$q->results}, 0, "0 rows retrieved" );

is($q->input("will_fail"), undef, "input (cached) is undef");
is($q->input("this_too"),  undef, "input (new) is undef");

