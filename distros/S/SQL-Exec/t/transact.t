use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

my $lax = {die_on_error => 0, print_error => 0, strict => undef};

test {
	connect(':memory:');
};

test {
	execute('create view v1 as select 1; select * from w',$lax);
	1
};

fail {
	query_one_value('select * from v1');
};

fail {
	execute('create view v2 as select 1; select * from w', {auto_transaction => 0});
	1
};

test {
	query_one_value('select * from v2');
};


