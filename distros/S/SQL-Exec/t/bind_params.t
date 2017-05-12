use strict;
use warnings;
use SQL::Exec::SQLite;
use Test::Subs;

my ($db, $st1);

test {
	$db = SQL::Exec::SQLite->new(':memory:');
	$db->execute('create table t (a, b)');
	$db->execute_multiple('insert into t (a, b) values (?, ?)',
		[1, 2],
		[1, 3],
		[5, 6],
		[7, 8],
		[9, 10]);
	1
};

test {
	$st1 = $db->prepare('select ?');
};

test {
	$db->query_one_value('select ?', 42) == 42;
};

test {
	$st1->query_one_value(1) == 1;
};

test {
	$st1->query_one_value(25) == 25;
};

failwith {
	$st1->query_one_value() == 25;
} 'Invalid number of parameter';

failwith {
	$st1->query_one_value(5, 3) == 25;
} 'Invalid number of parameter';

test {
	$db->query_one_line('select a, b from t where a = 5') ~~ [5, 6];
};

test {
	$db->query_one_line('select a, b from t where a = ?', 9) ~~ [9, 10];
};

test {
	$st1 = $db->prepare('select a, b from t where a = ?');
};

test {
	$st1->query_one_line(9) ~~ [9, 10];
};

test {
	$st1->query_one_line(1, {strict => undef});
};

test {
	not defined $st1->query_one_line(3, {die_on_error => 0, print_error => 0});
};

failwith {
	$st1->query_one_line(1);
} 'Too much rows';

failwith {
	$st1->query_one_line(3);
} 'Not enough data';


