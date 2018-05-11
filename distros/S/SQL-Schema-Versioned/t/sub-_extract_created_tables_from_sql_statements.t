#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use SQL::Schema::Versioned;

my @sql = (
    "CREATE TABLE t1 (i INT)",
    "create table if not exists t2 (i INT)",
    qq(create table  "table three" (i INT)),
    qq(create table
         `Table Four` (i INT)),
    "UDPATE t99 SET f1=1",
);

is_deeply(
    [SQL::Schema::Versioned::_extract_created_tables_from_sql_statements(@sql)],
    ["t1", "t2", "table three", "Table Four"],
);

DONE_TESTING:
done_testing;
