#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use SQL::Beautify;

my $sql = new SQL::Beautify(spaces => 2);
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


__DATA__
SELECT * FROM foo, bar, baz WHERE foo.id = bar.id AND bar.id = baz.id
"SELECT\n  *\nFROM\n  foo,\n  bar,\n  baz\nWHERE\n  foo.id = bar.id\n  AND\n  bar.id = baz.id\n"
