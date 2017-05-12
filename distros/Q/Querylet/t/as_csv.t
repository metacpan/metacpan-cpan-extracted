use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 3;

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT wafer_id
  FROM   grown_wafers

add column nulls:
	$value = undef;

add column zero:
	$value = 0;

output file: wafers.csv

no Querylet;

$q->write_output; # force execution of csv handler

ok(1, "made it here alive");
ok( -f "wafers.csv", "file created");
ok(unlink("wafers.csv"), "deleted file");
