use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run this test" if $@;

eval 'use Template 2.0 ()';
plan skip_all => "Template Toolkit required to run this test" if $@;

plan tests => 1;

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT wafer_id
  FROM   grown_wafers

output format: html

$q->output; # force execution of csv handler

no output

no Querylet;

ok(1, "made it here alive");
