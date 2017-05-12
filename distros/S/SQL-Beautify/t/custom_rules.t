#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use SQL::Beautify;

my $sql = new SQL::Beautify(spaces => 2);
my $query;
my $beauty;

ok($sql, 'got instance');

# Rebuild some default rules as custom rules.
$sql->add_rule('token-break', ',');
$sql->add_rule('token-break-reset', ';');
$sql->add_rule('back-break-token', [qw( GROUP ORDER LIMIT )]);
$sql->add_rule('token-break-over', 'BY');
$sql->add_rule('back-break-token-over', [qw( LEFT RIGHT INNER OUTER CROSS )]);
$sql->add_rule('break-token-break', [qw( UNION INTERSEPT EXCEPT )]);
$sql->add_rule('break-token-break', [qw( AND OR )]);

# Test plain text formatting.

while($query = <DATA>) {
	$beauty = <DATA>;
	$beauty = eval $beauty;

	ok($sql->query($query) eq $query, 'query set');
	ok($sql->query eq $query, 'query get');

	ok($sql->beautify eq $beauty, 'beautified');
}


__DATA__
SELECT * FROM foo, bar, baz WHERE foo.id = bar.id AND bar.id = baz.id
"SELECT\n  *\nFROM\n  foo,\n  bar,\n  baz\nWHERE\n  foo.id = bar.id\n  AND\n  bar.id = baz.id\n"
SELECT * FROM foo, bar, baz WHERE foo.id = bar.id AND bar.id = baz.id; SELECT 20;
"SELECT\n  *\nFROM\n  foo,\n  bar,\n  baz\nWHERE\n  foo.id = bar.id\n  AND\n  bar.id = baz.id;\nSELECT\n  20;\n"
SELECT ( SELECT "foo" FROM "bar" LIMIT 1 ) AS "foobar", COUNT(*) AS "my_count", FROM ( SELECT "another_table".* FROM "another_table", "yet_another_table" ) WHERE NOT EXISTS ( SELECT `baz` FROM `quux` WHERE `quux`.`moo` = `another_table`.`moo` ) ORDER BY ("x" + ("y" * "z"))
"SELECT (\n    SELECT\n      \"foo\"\n    FROM\n      \"bar\"\n    LIMIT 1\n  )\n  AS \"foobar\",\n  COUNT (\n    *\n  )\n  AS \"my_count\",\nFROM (\n    SELECT\n      \"another_table\".*\n    FROM\n      \"another_table\",\n      \"yet_another_table\"\n  )\nWHERE\n  NOT EXISTS (\n    SELECT\n      `baz`\n    FROM\n      `quux`\n    WHERE\n      `quux`.`moo` = `another_table`.`moo`\n  )\nORDER BY\n  (\n    \"x\" + (\n      \"y\" * \"z\"\n    )\n  )\n"
