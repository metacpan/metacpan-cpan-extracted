use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	connect(':memory:')
};

test {
	ref get_default_handle() eq 'SQL::Exec::SQLite'
};

test {
	query_one_value('select 42') == 42
};

test {
	query_one_line('select 42, 5') ~~ [42, 5]
};

test {
	query_all_lines('select 1, 2 union select 3, 4') ~~ [[1, 2],[3, 4]]
};

failwith {
	query_one_line('select 1, 2 union select 3, 4')
} 'Too much rows';


