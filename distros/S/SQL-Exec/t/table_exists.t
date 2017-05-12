use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	connect(':memory:');
	execute('create view v as select 10 a union select 20 a');
	execute('create table t (a, b, primary key (a))');
	execute('create trigger r before insert on t begin select 1; end');
	execute('attach database ":memory:" as db');
	execute('create table db.u (a, B, primary key (a, B))');
	1
};

test {
	table_exists('v')
};

test {
	table_exists('t')
};

todo {
	not table_exists('u')
};

test {
	not table_exists('main', 'u')
};

test {
	table_exists('main', 't')
};

test {
	table_exists('', 'main', 't')
};

test {
	table_exists('db', 'u');
};

test {
	not table_exists('db', 't');
};

test {
	not table_exists('w')
};

test {
	not table_exists('r')
};

test {
	table_exists('main.t')
};

test {
	table_exists('', 'main.t')
};

test {
	table_exists('db.u');
};

test {
	not table_exists('db.t');
};


# Test of the dummy fall back implementation
my $c;

test {
	$c = SQL::Exec::get_default_handle();
	SQL::Exec::__table_exists_dummy($c, undef, undef, 'v')
};

test {
	SQL::Exec::__table_exists_dummy($c, undef, undef, 't')
};

todo {
	not SQL::Exec::__table_exists_dummy($c, undef, undef, 'u')
};

test {
	not SQL::Exec::__table_exists_dummy($c, undef, 'main', 'u')
};

test {
	SQL::Exec::__table_exists_dummy($c, undef, 'main', 't')
};

test {
	SQL::Exec::__table_exists_dummy($c, '', 'main', 't')
};

test {
	SQL::Exec::__table_exists_dummy($c, undef, 'db', 'u');
};

test {
	not SQL::Exec::__table_exists_dummy($c, undef, 'db', 't');
};

test {
	not SQL::Exec::__table_exists_dummy($c, undef, undef, 'w')
};

test {
	not SQL::Exec::__table_exists_dummy($c, undef, undef, 'r')
};

test {
	SQL::Exec::__table_exists_dummy($c, undef, 'main.t')
};

test {
	SQL::Exec::__table_exists_dummy($c, '', 'main.t')
};

test {
	SQL::Exec::__table_exists_dummy($c, undef, 'db.u');
};

test {
	not SQL::Exec::__table_exists_dummy($c, undef, 'db.t');
};

test {
	get_primary_key('t') ~~ ['a'];
};

test {
	use Data::Dumper;
	get_primary_key('db', 'u') ~~ ['a', 'b'];
};

fail {
	use Data::Dumper;
	get_primary_key('db', 't') ~~ ['a', 'b'];
};


