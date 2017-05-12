use strict;
use warnings;
use SQL::Exec::SQLite;
use Test::Subs;

my ($db, $st1, $st2);

test {
	$db = SQL::Exec::SQLite->new(':memory:');
	$db->execute('create table t (a)');
	1
};

test {
	my $st = $db->prepare('select 42');
	$st->query_one_value() == 42
};

test {
	$st1 = $db->prepare('insert into t (a) values (?)');
};

test {
	$st2 = $db->prepare('select count(*) from t');
};

test {
	$st1->execute(1);
};

test {
	$st2->query_one_value() == 1;
};

test {
	$st1->execute(5, 10);
};

test {
	$st2->query_one_value() == 3;
};


