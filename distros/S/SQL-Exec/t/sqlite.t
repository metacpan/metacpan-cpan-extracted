use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	connect(':memory:');
	execute('create view v as select 10 a union select 20 a');
	1
};

test {
	for (1..100) { query_one_line('select a from v', {strict => undef}) }
	1
};

test {
	for (1..100) { query_all_lines('select a from v') }
	1
};

test {
	for (1..100) { query_one_value('select a from v', {strict => undef}) }
	1
};

test {
	for (1..100) { query_one_column('select a from v') }
	1
};



