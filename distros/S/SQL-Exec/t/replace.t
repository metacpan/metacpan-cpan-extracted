use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

{
	package Local::Foo;
	sub replace { $_[1] =~ s/1/4/; $_[1] }
}
my $r = bless [], 'Local::Foo';

test {
	connect(':memory:');
};

test {
	query_one_value('select 1', { replace => sub { s/1/2/ } }) == 2
};

test {
	query_one_value('select 1', { replace => { 1 => 3 } }) == 3
};

test {
	query_one_value('select 1', { replace => $r }) == 4
};

test {
	replace(1 => 5);
	query_one_value('select 1') == 5
};

test {
	query_one_value('select 1', { replace => 0 }) == 1
};

test {
	replace(String::Replace->new(table_name => 't'));
	execute('create table table_name (a)');
	replace(table_name => 't');
	execute('insert into table_name values (1)');
	query_one_value('select * from table_name', { replace => sub { s/table_name/t/g } }) == 1
}

