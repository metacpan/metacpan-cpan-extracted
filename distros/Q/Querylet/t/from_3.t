use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 5;

require Querylet::Query;

Querylet::Query->register_input_handler(
	three => sub { $_[0]->{input}->{$_[1]} = 3 }
);

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT material, diameter
  FROM   grown_wafers
  WHERE diameter = ?
  GROUP BY material
  ORDER BY material, diameter

input type: three

input: three

query parameter: $input->{three}

delete column one

no output

no Querylet;

ok(1, "made it here alive");
is( @{$q->results}, 5, "5 rows retrieved" );
is($q->results->[0]->{diameter}, 3, "diameter as requested" );

is($q->input("three"),    3, "parameter is set");
is($q->input("tres"),     3, "parameter sets itself");

