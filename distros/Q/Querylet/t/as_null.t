use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 2;

use Querylet;

sub null {}
Querylet::Query->register_output_handler(null => \&null);

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT material, COUNT(*) AS howmany, 1 AS one
  FROM   grown_wafers
  WHERE diameter = ?
  GROUP BY material
  ORDER BY material, diameter

query parameter: 3

delete column one

munge rows:
	$row->{howmany} *= 2

output format: null

no output

no Querylet;

ok(1, "made it here alive");
is( $q->output, undef, "no output (null method)" );

