use strict;
use warnings;
use Test::More;
use PDL;

use_ok('PDL::DuckDB', qw(duckdb_connect duckdb_version));

my $ver = duckdb_version();
ok(defined $ver && length $ver, 'duckdb_version returns version (' . $ver . ')');

my $db = duckdb_connect(':memory:');
isa_ok($db, 'PDL::DuckDB::Connection');

$db->exec('CREATE TABLE sales (grp VARCHAR, qty INTEGER, price DOUBLE)');
$db->exec("INSERT INTO sales VALUES ('a', 2, 1.5), ('a', 3, 2.5), ('b', 4, 10.0)");

my $cols = $db->query_pdl(
    'SELECT grp, CAST(SUM(qty) AS BIGINT) AS total_qty, AVG(price) AS avg_price FROM sales GROUP BY grp ORDER BY grp'
);

is_deeply($cols->{grp}, ['a', 'b'], 'VARCHAR group column matches');
is_deeply($cols->{total_qty}->unpdl, [5, 4], 'BIGINT SUM column returned as PDL ndarray');
is_deeply($cols->{avg_price}->unpdl, [2.0, 10.0], 'DOUBLE AVG column returned as PDL ndarray');

done_testing();
