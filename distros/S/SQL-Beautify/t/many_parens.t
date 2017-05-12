#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use SQL::Beautify;

my $sql = new SQL::Beautify(
	spaces => 2,
);

my $query = <DATA>;
my $beauty = <DATA>;

$beauty = eval $beauty;

ok($sql, 'got instance');

ok($sql->query($query) eq $query, 'query set');
ok($sql->query eq $query, 'query get');

ok($sql->beautify eq $beauty, 'beautified');

__DATA__
SELECT ( SELECT "foo" FROM "bar" LIMIT 1 ) AS "foobar", COUNT(*) AS "my_count", FROM ( SELECT "another_table".* FROM "another_table", "yet_another_table" ) WHERE NOT EXISTS ( SELECT `baz` FROM `quux` WHERE `quux`.`moo` = `another_table`.`moo` ) ORDER BY ("x" + ("y" * "z"))
"SELECT (\n    SELECT\n      \"foo\"\n    FROM\n      \"bar\"\n    LIMIT 1\n  )\n  AS \"foobar\",\n  COUNT (\n    *\n  )\n  AS \"my_count\",\nFROM (\n    SELECT\n      \"another_table\".*\n    FROM\n      \"another_table\",\n      \"yet_another_table\"\n  )\nWHERE\n  NOT EXISTS (\n    SELECT\n      `baz`\n    FROM\n      `quux`\n    WHERE\n      `quux`.`moo` = `another_table`.`moo`\n  )\nORDER BY\n  (\n    \"x\" + (\n      \"y\" * \"z\"\n    )\n  )\n"
