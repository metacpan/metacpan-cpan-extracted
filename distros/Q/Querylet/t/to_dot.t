use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 2;

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT wafer_id
  FROM   grown_wafers

add column nulls:
	$value = undef;

output file: .

no output

no Querylet;

$q->output; # force execution of csv handler

ok(1, "made it here alive");
is($q->write_output, undef, "no output; can't write to .");
