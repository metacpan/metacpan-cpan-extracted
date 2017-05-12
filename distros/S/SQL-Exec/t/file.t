use strict;
use warnings;
use SQL::Exec::SQLite ':all';
use Test::Subs;

test {
	connect(':memory:');
	execute('create table t (a, b)');
	execute_multiple('insert into t values (?, ?)', [1, 2], [3, 4]);
	not errstr;
};

test {
	pipe FIN, FOUT;
	query_to_file('select * from t', *FOUT, { line_separator => '', value_separator => ''});
	close FOUT;
	my $l = <FIN>;
	close FIN;
	$l eq "1234";
};

test {
	pipe FIN, FOUT;
	query_to_file('select * from t', *FOUT);
	close FOUT;
	my @l = <FIN>;
	close FIN;
	@l ~~ ["1;2\n", "3;4\n"];
};

