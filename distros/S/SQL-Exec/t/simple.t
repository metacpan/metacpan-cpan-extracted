use strict;
use warnings;
use SQL::Exec::SQLite;
use Test::Subs;

test {
	SQL::Exec::SQLite::connect(':memory:')
} "SQLite::connect(':memory:')";

test {
	ref SQL::Exec::get_default_handle() eq 'SQL::Exec::SQLite'
};

test {
	SQL::Exec::SQLite::query_one_value('select 42') == 42
};

test {
	SQL::Exec::SQLite::query_one_line('select 42, 5') ~~ [42, 5]
};

test {
	SQL::Exec::SQLite::query_all_lines('select 1, 2 union select 3, 4') ~~ [[1, 2],[3, 4]]
};

failwith {
	SQL::Exec::SQLite::query_one_line('select 1, 2 union select 3, 4')
} 'Too much rows';

my $c;

test {
	$c = SQL::Exec::SQLite->new(':memory:');
};

test {
	$c->query_one_value('select 42') == 42
};


