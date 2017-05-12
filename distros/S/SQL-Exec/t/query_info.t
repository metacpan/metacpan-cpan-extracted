use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	SQL::Exec::SQLite::connect(':memory:');
	execute('create table authors (id, name, age)');
	1
};

test {
	query_all_lines('select * from authors');
	get_fields() ~~ ['id', 'name', 'age'];
};

test {
	num_of_fields() == 3
};

test {
	num_of_params() == 0
};

my $st;

test {
	$st = prepare('select name, age from authors where id = ?');
	$st->num_of_params() == 1;
};

test {
	$st->num_of_fields() == 2;
};

test {
	$st->get_fields() ~~ [qw(name age)];
};

test {
	get_fields() ~~ [qw(id name age)];
};

