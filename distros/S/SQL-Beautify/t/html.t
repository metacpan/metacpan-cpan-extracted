#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use SQL::Beautify;

my $sql = new SQL::Beautify(
	spaces => 1,
	break => '<br>',
	space => '&nbsp;',
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
SELECT * FROM foo, bar, baz WHERE foo.id = bar.id AND bar.id = baz.id
"SELECT<br>&nbsp;*<br>FROM<br>&nbsp;foo,<br>&nbsp;bar,<br>&nbsp;baz<br>WHERE<br>&nbsp;foo.id&nbsp;=&nbsp;bar.id<br>&nbsp;AND<br>&nbsp;bar.id&nbsp;=&nbsp;baz.id<br>"
