use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	set_options(print_error => 0, print_warning => 0);
	connect(':memory:');
	execute('create table t (a, B, cC)');
	execute_multiple('insert into t (a, B, cC) values (?, ?, ?)',
		[1, 2, 3], [4, 5, 6], [7, 8, 9]);
};

my (%h, $h, @h);

test {
	%h = query_one_hash('select A, B, CC from t where a = 1');
};

test {
	$h{a} == 1 and $h{b} == 2 and $h{cc} == 3;
};

test {
	$h = query_one_hash('select A, B, CC from t where a = 1');
};

test {
	$h->{a} == 1 and $h->{b} == 2 and $h->{cc} == 3;
};

test {
	@h = query_all_hashes('select A, B, CC from t');
};

test {
	@h == 3 and $h[1]{a} == 4 and $h[1]{b} == 5 and $h[1]{cc} == 6;
};


