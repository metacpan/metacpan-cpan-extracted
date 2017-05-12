use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 6;

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT material, COUNT(*) AS howmany, 1 AS one, 2 AS two
  FROM   grown_wafers
  WHERE diameter = ?
  GROUP BY material
  ORDER BY material, diameter

query parameter: 4

delete column one

delete columns where:
	not(grep { $_ ne "1" } @values)

munge rows:
	$row->{howmany} *= 2

output format: html

output file: never_gonna_happen.html

no output

no Querylet;

ok(1, "made it here alive");

isa_ok($q, "Querylet::Query");
isa_ok($q->results, "ARRAY");
isa_ok($q->results->[0], "HASH");

cmp_ok(@{$q->results}, '==', 5, "correct number of results");

is($q->results->[0]->{material},    'GaAs', 'first material correct');

