#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use SQL::Beautify;

my $sql = new SQL::Beautify(
	spaces => 2,
	wrap => {
		keywords => [ "\x1B[0;32m", "\x1B[0m" ],
		constants => [ "\x1B[0;31m", "\x1B[0m" ],
	},
);

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
SELECT * FROM foo, bar, baz WHERE foo.id = bar.id AND bar.id = baz.id AND foo.name = 'quux' AND bar.id = 42
"\e[0;32mSELECT\e[0m\n  *\n\e[0;32mFROM\e[0m\n  foo,\n  bar,\n  baz\n\e[0;32mWHERE\e[0m\n  foo.id = bar.id\n  \e[0;32mAND\e[0m\n  bar.id = baz.id\n  \e[0;32mAND\e[0m\n  foo.name = \e[0;31m'quux'\e[0m\n  \e[0;32mAND\e[0m\n  bar.id = \e[0;31m42\e[0m\n"
