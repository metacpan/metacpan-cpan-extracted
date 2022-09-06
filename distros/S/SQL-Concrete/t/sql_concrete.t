use strict; use warnings;

use Test::More tests => 60;
use Test::Differences;
use Data::Dumper;
use SQL::Concrete qw( :all );
use SQL::Concrete::Dollars _prefix => 'dollar_', 'sql_render';

my $do_dollars;

sub sql_ok {
	my $code = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	s/\A\s+//, s/\s+\z// for $code;
	my @result;
	my $func = $do_dollars ? 'dollar_sql_render' : 'sql_render';
	my $name = $do_dollars ? "(\$) $code" : $code;
	eval "\@result = $func $code; 1"
		? eq_or_diff \@result, \@_, $name
		: do { fail $name; diag $@ };
}

sub sql_error_ok {
	my ( $code, $re ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	s/\A\s+//, s/\s+\z// for $code;
	local $@;
	my @result;
	eval "\@result = sql_render $code; 1"
		? do { fail $code; diag Dumper \@result }
		: like $@, $re, "!! $code";
}

#######################################################################

can_ok __PACKAGE__, qw( sql_render sql VALUES SET SELECT );

# literals
sql_ok q[] => '';
sql_ok q[ 'SELECT * FROM mytable' ]     => 'SELECT * FROM mytable';
sql_ok q[ qw( SELECT * FROM mytable ) ] => 'SELECT * FROM mytable';

# scalarref
sql_ok       q[ \5 ] =>   '?', 5;
sql_ok q[ 'x=', \5 ] => 'x=?', 5;

# sql()
sql_ok q[ sql() ]            => '';
sql_ok q[ sql 'RAW SQL' ]    => 'RAW SQL';
sql_ok q[ sql \5 ]           => '?', 5;
sql_ok q[ sql sql \5 ]       => '?', 5;
sql_ok q[ sql sql sql \5 ]   => '?', 5;
sql_ok q[ sql sql(), sql() ] => '';

# arrayref
sql_error_ok q[ [] ] => qr/empty array/;
sql_ok q[ [ 1, 2, 3 ] ] => '?, ?, ?', 1, 2, 3;
sql_ok q[ [ 1, sql(2), 3 ] ] => '?, 2, ?', 1, 3;

# hashref
sql_error_ok q[ { field => \5 } ] => qr/unrecognized SCALAR value for key 'field' in hash/;
sql_ok q[ {} ]                                  => '1=1';
sql_ok q[ { one => 1, two => 2 } ]              => '(one=? AND two=?)', 1, 2;
sql_ok q[ { x => 1, y => sql '2' } ]            => '(x=? AND y=2)', 1;
sql_ok q[ { x => 1, y => undef } ]              => '(x=? AND y IS NULL)', 1;
sql_ok q[ { field => [] } ]                     => '1 IN (0)';
sql_ok q[ 'NOT', { field => [] } ]              => '1 IN (1)';
sql_ok q[ { field => [ 'one', 'two' ] } ]       => 'field IN (?, ?)', 'one', 'two';
sql_ok q[ { field => [ 'one', sql 'two' ] } ]   => 'field IN (?, two)', 'one';
sql_ok q[ { field => [ 1, sql \5, '*', \5 ] } ] => 'field IN (?, ? * ?)', 1, 5, 5;

# VALUES
sql_ok q[ VALUES [] ]                                   => 'VALUES()';
sql_ok q[ VALUES [ 'one', 'two' ] ]                     => 'VALUES(?, ?)', 'one', 'two';
sql_ok q[ VALUES [ 'one', sql 'two' ] ]                 => 'VALUES(?, two)', 'one';
sql_ok q[ VALUES [ 1, sql \5, '*', \5 ] ]               => 'VALUES(?, ? * ?)', 1, 5, 5;
sql_ok q[ VALUES {} ]                                   => '() VALUES()';
sql_ok q[ VALUES { one => 1, two => 2 } ]               => '(one, two) VALUES(?, ?)', 1, 2;
sql_ok q[ VALUES { one => 1, two => sql \5, '*', \5 } ] => '(one, two) VALUES(?, ? * ?)', 1, 5, 5;

# SET
sql_ok q[ SET one => 1, two => 2 ]       => 'SET one=?, two=?', 1, 2;
sql_ok q[ SET one => 1, two => sql '2' ] => 'SET one=?, two=2', 1;

# SELECT
sql_error_ok q[ SELECT    ] => qr/empty SELECT/;
sql_error_ok q[ SELECT [] ] => qr/empty first row in SELECT/;
sql_error_ok q[ SELECT {} ] => qr/empty first row in SELECT/;

sql_ok q[ SELECT undef, [ 1 ] ] =>
	'(SELECT ?) AS tbl0', 1;
sql_ok q[ SELECT [ 1 ] ] =>
	'(SELECT ?)', 1;
sql_ok q[ SELECT undef, { a => 1 } ] =>
	'(SELECT ? AS a) AS tbl0', 1;
sql_ok q[ SELECT { a => 1 } ] =>
	'(SELECT ? AS a)', 1;
sql_ok q[ SELECT undef, [ 1, 2 ] ] =>
	'(SELECT ?, ?) AS tbl0', 1, 2;
sql_ok q[ SELECT undef, { one => 1, two => 2 } ] =>
	'(SELECT ? AS one, ? AS two) AS tbl0', 1, 2;
sql_ok q[ SELECT { one => 1, two => 2 } ] =>
	'(SELECT ? AS one, ? AS two)', 1, 2;
sql_ok q[ SELECT undef, [ 1, 2 ], [ 3, 4 ] ] =>
	'(SELECT ?, ? UNION ALL SELECT ?, ?) AS tbl0', 1, 2, 3, 4;
sql_ok q[ SELECT [ 1, 2 ], [ 3, 4 ] ] =>
	'(SELECT ?, ? UNION ALL SELECT ?, ?)', 1, 2, 3, 4;
sql_ok q[ SELECT undef, ( { one => 1, two => 2 } ) x 2 ] =>
	'(SELECT ? AS one, ? AS two UNION ALL SELECT ?, ?) AS tbl0', ( 1, 2 ) x 2;
sql_ok q[ SELECT +( { one => 1, two => 2 } ) x 2 ] =>
	'(SELECT ? AS one, ? AS two UNION ALL SELECT ?, ?)', ( 1, 2 ) x 2;
sql_ok q[ SELECT( undef, [ 1 ] ), 'JOIN', SELECT( undef, [ 2 ] ) ] =>
	'(SELECT ?) AS tbl0 JOIN (SELECT ?) AS tbl1', 1, 2;
sql_ok q[ SELECT undef, [ sql 1 ] ] =>
	'(SELECT 1) AS tbl0';
sql_ok q[ SELECT [ sql 1 ] ] =>
	'(SELECT 1)';
sql_ok q[ SELECT undef, { a => sql 1 } ] =>
	'(SELECT 1 AS a) AS tbl0';
sql_ok q[ SELECT undef, [ sql \1 ] ] =>
	'(SELECT ?) AS tbl0', 1;
sql_ok q[ SELECT undef, [ sql '1=', \1 ] ] =>
	'(SELECT 1=?) AS tbl0', 1;
sql_ok q[ SELECT( [ 1 ] ), 'AS mytable' ] =>
	'(SELECT ?) AS mytable', 1;
sql_ok q[ SELECT undef, [ undef ] ] =>
	'(SELECT ?) AS tbl0', undef;
sql_ok q[ SELECT undef, { a => undef } ] =>
	'(SELECT ? AS a) AS tbl0', undef;

# dollar placeholders
$do_dollars = 1;
sql_ok q[ \1 ]
	=> '$1', 1;
sql_ok q[ [ 1, 2, 3 ] ]
	=> '$1, $2, $3', 1, 2, 3;
sql_ok q[ { x => [ 1, sql([ 2 ]), 3 ], y => 4 } ]
	=> '(x IN ($1, $2, $3) AND y=$4)', 1, 2, 3, 4;
