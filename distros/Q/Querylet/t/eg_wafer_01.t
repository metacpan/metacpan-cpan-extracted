use Test::More;

eval 'use DBD::SQLite 1.0 ()';
plan skip_all => "DBD::SQLite required to run test querylet" if $@;

plan tests => 8;

use Querylet;

database: dbi:SQLite:dbname=./t/wafers.db

query:
  SELECT wafer_id, material, diameter, failurecode
  FROM   grown_wafers
  WHERE  reactor_id = 105
    AND  product_type <> 'Calibration'
  ORDER BY material, diameter

delete rows where:
	$row->{material} !~ /^[a-z]+$/i

add column surface_area:
  $value = $row->{diameter} * 3.14;

delete column diameter

add column cost:
  $value = $row->{surface_area} * 100 if $row->{material} eq 'GaAs';
  $value = $row->{surface_area} * 200 if $row->{material} eq 'InP';

munge column failurecode:
  $value = 10 if $value == 3; # 3's have been reclassified

munge all values:
  $value = '(null)' unless defined $value;

no output

no Querylet;

ok(1, "made it here alive");

isa_ok($q, "Querylet::Query");
isa_ok($q->results, "ARRAY");
isa_ok($q->results->[0], "HASH");

cmp_ok(@{$q->results}, '==', 160, "correct number of results");

is($q->results->[0]->{material},     'GaAs', 'first material correct');
is($q->results->[0]->{surface_area},   6.28, 'first surfarea correct',);
is($q->results->[0]->{cost},            628, 'first cost correct',);

