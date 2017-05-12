use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Test::Differences;
use Data::Dumper;
use SQL::Interpol ':all';

sub sql_ok {
	my $code = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	s/\A\s+//, s/\s+\z// for $code;
	my @result;
	eval "\@result = sql_interp $code; 1"
		? eq_or_diff \@result, \@_, $code
		: do { fail $code; diag $@ };
}

sub sql_error_ok {
	my ( $code, $re ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	s/\A\s+//, s/\s+\z// for $code;
	local $@;
	my @result;
	eval "\@result = sql_interp $code; 1"
		? do { fail $code; diag Dumper \@result }
		: like $@, $re, "!! $code";
}

#######################################################################

can_ok __PACKAGE__, qw( sql_interp sql );

#== trivial cases
sql_ok q[] => '';
sql_ok q[ 'SELECT * FROM mytable' ] => 'SELECT * FROM mytable';
sql_ok q[ \5 ] => '?', 5;

# test with sql()
sql_ok q[ sql() ]            => '';
sql_ok q[ sql('test') ]      => 'test';
sql_ok q[ sql(\5) ]          => '?', 5;
sql_ok q[ sql(sql(\5)) ]     => '?', 5;
sql_ok q[ sql(sql(),sql()) ] => '';

#== INSERT
sql_ok q[ 'INSERT INTO mytable', \5 ] =>
	'INSERT INTO mytable VALUES(?)', 5;
sql_ok q[ 'REPLACE INTO mytable', \5 ] =>
	'REPLACE INTO mytable VALUES(?)', 5;
sql_ok q[ 'INSERT INTO mytable', sql(5) ] =>
	"INSERT INTO mytable 5"; # invalid
# OK in mysql
sql_ok q[ 'INSERT INTO mytable', [] ] =>
	'INSERT INTO mytable VALUES()';
sql_ok q[ 'INSERT INTO mytable', [ 'one', 'two' ] ] =>
	'INSERT INTO mytable VALUES(?, ?)', 'one', 'two';
sql_ok q[ 'INSERT INTO mytable', [ 'one', sql('two') ] ] =>
	'INSERT INTO mytable VALUES(?, two)', 'one';
sql_ok q[ 'INSERT INTO mytable', [ 1, sql(\5, '*', \5) ] ] =>
	'INSERT INTO mytable VALUES(?, ? * ?)', 1, 5, 5;
# OK in mysql
sql_ok q[ 'INSERT INTO mytable', {} ] =>
	'INSERT INTO mytable () VALUES()';
sql_ok q[ 'INSERT INTO mytable', { one => 1, two => 2 } ] =>
	'INSERT INTO mytable (one, two) VALUES(?, ?)', 1, 2;
sql_ok q[ 'INSERT INTO mytable', { one => 1, two => sql(\5, '*', \5) } ] =>
	'INSERT INTO mytable (one, two) VALUES(?, ? * ?)', 1, 5, 5;
# mysql
sql_ok q[ 'INSERT HIGH_PRIORITY IGNORE INTO mytable', [ 'one', 'two' ] ] =>
	'INSERT HIGH_PRIORITY IGNORE INTO mytable VALUES(?, ?)', 'one', 'two';

# IN
# note: 'WHERE field in ()' NOT OK in mysql.
sql_ok q[ 'WHERE field IN', \5 ]        => 'WHERE field IN (?)', 5;
sql_ok q[ 'WHERE field IN', \ [ 1,2 ] ] => 'WHERE field IN (?, ?)', 1, 2;
sql_ok q[ 'WHERE field IN', sql(5) ]    => "WHERE field IN 5"; # invalid
sql_ok q[ 'WHERE field IN', [] ]        => 'WHERE 1=0';
sql_ok q[ 'WHERE field NOT IN', [] ]    => 'WHERE 1=1';
sql_ok q[ 'WHERE field in', [] ]        => 'WHERE 1=0';
sql_ok q[ 'WHERE', { field => [] } ]    => 'WHERE 1=0';

sql_ok q[ 'WHERE field IN', [ 'one', 'two' ] ] =>
	'WHERE field IN (?, ?)', 'one', 'two';
sql_ok q[ 'WHERE field IN', [ 'one', sql('two') ] ] =>
	'WHERE field IN (?, two)', 'one';
sql_ok q[ 'WHERE field IN', [ 1, sql(\5, '*', \5) ] ] =>
	'WHERE field IN (?, ? * ?)', 1, 5, 5;
sql_ok q[ 'WHERE', { field => [ 'one', 'two' ] } ] =>
	'WHERE field IN (?, ?)', 'one', 'two';
sql_ok q[ 'WHERE', { field => [ 1, sql(\5, '*', \5) ] } ] =>
	'WHERE field IN (?, ? * ?)', 1, 5, 5;

# SET
sql_ok q[ 'UPDATE mytable SET', { one => 1, two => 2 } ] =>
	'UPDATE mytable SET one=?, two=?', 1, 2;
sql_ok q[ 'UPDATE mytable SET', { one => 1, two => 5, three => sql('3') } ] =>
	'UPDATE mytable SET one=?, three=3, two=?', 1, 5;
#FIX--what if size of hash is zero? error?

# WHERE hashref
sql_ok q[ 'WHERE', {} ]                        => 'WHERE 1=1';
sql_ok q[ 'WHERE', { one => 1, two => 2 } ]    => 'WHERE (one=? AND two=?)', 1, 2;
sql_ok q[ 'WHERE', { x => 1, y => sql('2') } ] => 'WHERE (x=? AND y=2)', 1;
sql_ok q[ 'WHERE', { x => 1, y => undef } ]    => 'WHERE (x=? AND y IS NULL)', 1;

# WHERE x=
sql_ok q[ 'WHERE x=', \5 ] => 'WHERE x= ?', 5;

# table references
sql_error_ok q[ 'FROM', [] ], qr/table reference has zero rows/;
sql_error_ok q[ 'FROM', [ [] ] ], qr/table reference has zero columns/;
sql_error_ok q[ '', [ [] ] ], qr/table reference has zero columns/;
sql_error_ok q[ 'FROM', [ {} ] ], qr/table reference has zero columns/;
sql_error_ok q[ '', [ {} ] ], qr/table reference has zero columns/;
sql_ok q[ 'FROM', [ [ 1 ] ] ] =>
	'FROM (SELECT ?) AS tbl0', 1;
sql_ok q[ '',     [ [ 1 ] ] ] =>
	'(SELECT ?)', 1;
sql_ok q[ 'FROM', [ { a => 1 } ] ] =>
	'FROM (SELECT ? AS a) AS tbl0', 1;
sql_ok q[ '',     [ { a => 1 } ] ] =>
	'(SELECT ? AS a)', 1;
sql_ok q[ 'FROM', [ [ 1,2 ] ] ] =>
	'FROM (SELECT ?, ?) AS tbl0', 1, 2;
sql_ok q[ 'FROM', [ { one => 1, two => 2 } ] ] =>
	'FROM (SELECT ? AS one, ? AS two) AS tbl0', 1, 2;
sql_ok q[ '',     [ { one => 1, two => 2 } ] ] =>
	'(SELECT ? AS one, ? AS two)', 1, 2;
sql_ok q[ 'FROM', [ [ 1,2 ], [ 3,4 ] ] ] =>
	'FROM (SELECT ?, ? UNION ALL SELECT ?, ?) AS tbl0', 1, 2, 3, 4;
sql_ok q[ '', [ [ 1,2 ], [ 3,4 ] ] ] =>
	'(SELECT ?, ? UNION ALL SELECT ?, ?)', 1, 2, 3, 4;
sql_ok q[ 'FROM', [ ( { one => 1, two => 2 } ) x 2 ] ] =>
	'FROM (SELECT ? AS one, ? AS two UNION ALL SELECT ?, ?) AS tbl0', 1, 2, 1, 2;
sql_ok q[ '', [ ( { one => 1, two => 2 } ) x 2 ] ] =>
	'(SELECT ? AS one, ? AS two UNION ALL SELECT ?, ?)', 1, 2, 1, 2;
sql_ok q[ 'FROM', [ [ 1 ] ], 'JOIN', [ [ 2 ] ] ] =>
	'FROM (SELECT ?) AS tbl0 JOIN (SELECT ?) AS tbl1', 1, 2;
sql_ok q[ 'FROM', [ [ sql(1) ] ] ] =>
	'FROM (SELECT 1) AS tbl0';
sql_ok q[ '', [ [ sql(1) ] ] ] =>
	'(SELECT 1)';
sql_ok q[ 'FROM', [ { a => sql(1) } ] ] =>
	'FROM (SELECT 1 AS a) AS tbl0';
sql_ok q[ 'FROM', [ [ sql(\1) ] ] ] =>
	'FROM (SELECT ?) AS tbl0', 1;
sql_ok q[ 'FROM', [ [ sql('1=', \1) ] ] ] =>
	'FROM (SELECT 1= ?) AS tbl0', 1;
sql_ok q[ 'FROM', [ [ 1 ] ], ' AS mytable' ] =>
	'FROM (SELECT ?) AS mytable', 1;
sql_ok q[ 'FROM', [ [ undef ] ] ] =>
	'FROM (SELECT ?) AS tbl0', undef;
sql_ok q[ 'FROM', [ { a => undef } ] ] =>
	'FROM (SELECT ? AS a) AS tbl0', undef;

sql_error_ok q[ { some_column => { '1 or 1', '1' } } ], qr/unrecognized HASH value in aggregate/;

done_testing;
