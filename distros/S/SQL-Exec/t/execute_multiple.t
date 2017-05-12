use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	set_options(print_error => 0, print_warning => 0);
	connect(':memory:');
	execute('
		create table t (a);
		create table u (a unique);
		create table v (a unique);
		create table w (a unique)');
	not errstr;
};

test {
	execute_multiple('insert into t values (?)', [1], [2], [3])
};

test {
	query_one_column('select a from t') ~~ [1, 2, 3]
};

test {
	execute_multiple('insert into t values (?)', 1, 2, 3)
};

test {
	execute_multiple('insert into t values (?)', [[1], [2], [3]])
};

fail {
	execute_multiple('insert into u values (?)', 1, 2, 2)
};

test {
	query_one_column('select a from u') ~~ [ ]
};

fail {
	execute_multiple('insert into u values (?)', 1, 2, 2, { auto_transaction => 0 })
};

test {
	query_one_column('select a from u') ~~ [1, 2]
};

test {
	execute_multiple('insert into w values (?)', 1, 2, 2, 3, { stop_on_error => 0, die_on_error => 0, strict => 0 })
};

test {
	query_one_column('select a from w') ~~ [1, 2, 3]
};


