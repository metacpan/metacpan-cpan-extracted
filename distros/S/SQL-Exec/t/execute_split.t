use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	connect(':memory:');
	execute('create table t (a)');
	not errstr;
};

test {
	execute(['insert into t values (1)', 'insert into t values (3); insert into t values (4)'])
};

test {
	query_one_column('select a from t') ~~ [1, 3, 4]
};

