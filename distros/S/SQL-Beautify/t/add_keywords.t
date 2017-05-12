#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use SQL::Beautify;

my $sql = new SQL::Beautify(
	spaces => 2,
	wrap => {
		keywords => [ "<", ">" ],
	},
	keywords => [ "MY_KEYWORD" ],
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

$sql->add_keywords('ANOTHER_KEYWORD');

ok($sql->beautify eq $beauty, 'beautified');

__DATA__
MY_KEYWORD "foo" ANOTHER_KEYWORD "bar";
"<MY_KEYWORD> \"foo\" <ANOTHER_KEYWORD> \"bar\";\n"
