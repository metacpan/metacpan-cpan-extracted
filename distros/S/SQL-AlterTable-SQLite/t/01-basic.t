#!perl

use 5.010;
use strict;
use warnings;

use SQL::AlterTable::SQLite qw(gen_sql_alter_table);
use Test::Exception;
use Test::More 0.98;
use Test::WithDB::SQLite;

my $twdb = Test::WithDB::SQLite->new;
my $dbh  = $twdb->create_db;
diag "temporary database is created at ", $dbh->sqlite_db_filename;

$dbh->do("CREATE TABLE t (a INT, b INT)") or die "Can't create table";

is_deeply(gen_sql_alter_table(dbh=>$dbh, table=>'t'), [], 'noop -> empty');

dies_ok { gen_sql_alter_table(dbh=>$dbh, table=>'t2') }
    'alter non-existing table -> dies';

dies_ok { gen_sql_alter_table(dbh=>$dbh, table=>'t', add_columns=>[a => 'INT']) }
    'add column the same name as existing -> dies';

dies_ok { gen_sql_alter_table(dbh=>$dbh, table=>'t', delete_columns=>['c']) }
    'drop non-existing column -> dies';

dies_ok { gen_sql_alter_table(dbh=>$dbh, table=>'t', modify_columns=>['c' => "INT"]) }
    'modify non-existing column -> dies';

dies_ok { gen_sql_alter_table(dbh=>$dbh, table=>'t', rename_columns=>['c' => 'd']) }
    'rename non-existing column -> dies';

dies_ok { gen_sql_alter_table(dbh=>$dbh, table=>'t', rename_columns=>['a' => 'b']) }
    'rename to existing column -> dies';

my $res = gen_sql_alter_table(
    dbh            => $dbh,
    table          => 't',
    delete_columns => ['b'],
    modify_columns => ['a', 'INT NOT NULL'],
    rename_columns => ['a', 'a2'],
    add_columns    => ['c', 'TEXT'],
    rename_table   => 't2',
);

is_deeply($res, [
    'CREATE TABLE "_t_tmp" ("a2" INT NOT NULL)',
    'INSERT INTO "_t_tmp" ("a2") SELECT "a" FROM "t"',
    'DROP TABLE "t"',
    'ALTER TABLE "_t_tmp" RENAME TO "t2"',
    'ALTER TABLE "t2" ADD COLUMN "c" TEXT',
]) or diag explain $res;

DONE_TESTING:
done_testing;
$twdb->done;
