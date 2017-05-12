use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 4;

use Querylet;

sub handler { sub { $main::passed = 1 } }
Querylet::Query->register_output_handler(code => \&handler);

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

output format: code

no Querylet;

ok(1, "made it here alive");
isa_ok( $q->output, 'CODE', 'result of $q->output' );

is($main::passed, undef, 'output sub uncalled');

$q->write_output;

is($main::passed, 1, 'output sub called');
