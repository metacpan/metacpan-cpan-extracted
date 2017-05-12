use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	connect(':memory:');
	execute('create view v as select 10 a, 20 B');
	execute('create table t (a, B)');
	execute('attach database ":memory:" as db');
	execute('create table db.u (a, B)');
	1
};

test {
	get_columns('v') ~~ ['a', 'b'];
};

test {
	get_columns('t') ~~ ['a', 'b'];
};

test {
	get_columns('main', 'v') ~~ ['a', 'b'];
};

test {
	get_columns('main.t') ~~ ['a', 'b'];
};

test {
	get_columns('db', 'u') ~~ ['a', 'b'];
};

test {
	get_columns('db.u') ~~ ['a', 'b'];
};

fail {
	get_columns('z');
};

# we are testing the default, bad implementation.
my $c;

test {
	$c = SQL::Exec::get_default_handle();
	SQL::Exec::__get_columns_dummy($c, undef, undef, 'v') ~~ ['a', 'b'];
};

test {
	SQL::Exec::__get_columns_dummy($c, undef, undef, 't') ~~ ['a', 'b'];
};

test {
	SQL::Exec::__get_columns_dummy($c, undef, 'main', 'v') ~~ ['a', 'b'];
};

test {
	SQL::Exec::__get_columns_dummy($c, undef, 'main.t') ~~ ['a', 'b'];
};

test {
	SQL::Exec::__get_columns_dummy($c, undef, 'db', 'u') ~~ ['a', 'b'];
};

test {
	SQL::Exec::__get_columns_dummy($c, undef, 'db.u') ~~ ['a', 'b'];
};

