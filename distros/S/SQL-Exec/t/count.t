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
	count_lines('select * from v') == 2
};

failwith {
	count_lines('select * from w') == 2
} 'no such table';


