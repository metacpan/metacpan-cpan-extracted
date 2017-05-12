#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use SQL::Beautify;

my $sql = new SQL::Beautify(spaces => 2, uc_keywords => 1);
my $query;
my $beauty;

ok($sql, 'got instance');

# Test plain text formatting.
$query = <DATA>;
$beauty = <DATA>;

$beauty = eval $beauty;

ok($sql->query($query) eq $query, 'query set');
ok($sql->query eq $query, 'query get');

ok($sql->beautify eq $beauty, 'beautified');

# test mixed cases
$query = <DATA>;
$beauty = <DATA>;

$beauty = eval $beauty;

ok($sql->query($query) eq $query, 'query set');
ok($sql->query eq $query, 'query get');

ok($sql->beautify eq $beauty, 'beautified');

# all keywords 
$query = <DATA>;
$beauty = <DATA>;

$beauty = eval $beauty;

ok($sql->query($query) eq $query, 'query set');
ok($sql->query eq $query, 'query get');

ok($sql->beautify eq $beauty, 'beautified');

__DATA__
select * from foo, bar, baz where foo.id = bar.id and bar.id = baz.id
"SELECT\n  *\nFROM\n  foo,\n  bar,\n  baz\nWHERE\n  foo.id = bar.id\n  AND\n  bar.id = baz.id\n"
select * FROM foo, bar, baz where foo.id = bar.id AND bar.id = baz.id
"SELECT\n  *\nFROM\n  foo,\n  bar,\n  baz\nWHERE\n  foo.id = bar.id\n  AND\n  bar.id = baz.id\n"
select foo.id, bar.name FROM foo, bar, baz where foo.id = bar.id AND bar.id = baz.id OR bar.id != foo.id
"SELECT\n  foo.id,\n  bar.name\nFROM\n  foo,\n  bar,\n  baz\nWHERE\n  foo.id = bar.id\n  AND\n  bar.id = baz.id\n  OR\n  bar.id != foo.id\n"
