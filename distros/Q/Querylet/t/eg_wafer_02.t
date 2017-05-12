use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run this test" if $@;

eval 'use Template 2.0 ()';
plan skip_all => "Template Toolkit required to run this test" if $@;

plan tests => 6;

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT material, COUNT(*) AS howmany, 1 AS one
  FROM   grown_wafers
  WHERE diameter = [% diameter %]
  GROUP BY material
  ORDER BY material, diameter

munge query:
	diameter => 4

munge query:
	diameter => 4

munge query:
	unused => 3

delete column one

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

