use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;


test {
	connect(':memory:');
	execute('create view v as select 1');
	query_one_value('select * from v') == 1
};

my $c;

test {
	$c = SQL::Exec::SQLite->new(':memory:');
	$c->execute('create view v as select 2');
	$c->query_one_value('select * from v') == 2
};

test {
	query_one_value('select * from v') == 1
};

failwith {
	prepare('select a from u');
} 'select a from u';


