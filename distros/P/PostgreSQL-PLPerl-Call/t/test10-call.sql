CREATE FUNCTION call_test10() RETURNS text
LANGUAGE plperlu AS $func$

use PostgreSQL::PLPerl::Call;

# XXX server process needs to have a working STDOUT
# else "ERROR:  Can't dup STDOUT:  Bad file descriptor" error
# from Test::Builder.

use Test::More 'no_plan';
my $Test = Test::More->builder;
$Test->output(\my $test_output);

my $row;
my @ary;

# ====== single-value single-row function ======

# --- no arguments
like call('pi()'), qr/^3.14159/;
# with schema
like call('pg_catalog.pi()'), qr/^3.14159/;
# without parens/types
like call('pi'),              qr/^3.14159/;
like call('pg_catalog.pi'),   qr/^3.14159/;

# bad calls
eval { call('pi()', 42) };
like $@, qr/there is no parameter \$1/;

# --- method call syntax
like PG->pi, qr/^3.14159/;
# bad calls
eval { PG->pi(42) };
like $@, qr/there is no parameter \$1/;

# --- one argument, simple types
is call('abs(int)', -42), 42;
is call('abs(float)', -42.5), '42.5';
is call('bit_length(text)', 'jose'), 32;

# --- one argument, multi-word types
is call('abs(double precision)', -42.5), '42.5';
is call('bit_length(character varying(90))', 'jose'), 32;

# --- lock calls
call('pg_try_advisory_lock_shared(bigint)', 1234);
call('pg_advisory_unlock_all()');

# bad calls
eval { call('abs(int)', -42.5) };
like $@, qr/invalid input syntax for integer/;
eval { call('abs(text)', -42.5) };
like $@, qr/function abs\(text\) does not exist/;
eval { call('abs(nonesuchtype)', -42.5) };
like $@, qr/type "nonesuchtype" does not exist/;

# --- multi-argument, simple types
is call('trunc(numeric,int)', 42.4382, 2), '42.43';

# --- unusual types from strings
is call('host(inet)',    '192.168.1.5/24'), '192.168.1.5';
is call('network(inet)', '192.168.1.5/24'), '192.168.1.0/24';
is call('abbrev(cidr)',  '10.1.0.0/16'),    '10.1/16';
is call('numnode(tsquery)', '(fat & rat) | cat'), 5;

spi_exec_query('create temp sequence seqn1 start with 42');
is call('nextval(regclass)', 'seqn1'), 42;
is call('nextval(text)',     'seqn1'), 43;

is call('string_to_array(text, text)', 'xx~^~yy~^~zz', '~^~'), '{xx,yy,zz}';

# --- array and array reference handling
is call('array_dims(text[])', '{a,b,c}'), '[1:3]';
is call('array_dims(text[])', [qw(a b c)]), '[1:3]';
is call('array_dims(text[])', [[1,2,3], [4,5,6]]), '[1:2][1:3]';
is call('array_cat(int[], int[])', [1,2,3], [2,1]), '{1,2,3,2,1}';


# ====== single-value multi-row function ======

@ary = call('unnest(int[])', '{11,12,13}');
is scalar @ary, 3;
is_deeply \@ary, [ 11, 12, 13 ];

@ary = call('generate_series(int,int)', 10, 19);
is scalar @ary, 10;
is_deeply \@ary, [ 10..19 ];

@ary = call('generate_series(int,int,int)', 10, 19, 4);
is_deeply \@ary, [ 10, 14, 18 ];

@ary = call('generate_series(timestamp,timestamp,interval)', '2008-03-01', '2008-03-02', '12 hours');
is_deeply \@ary, [ '2008-03-01 00:00:00', '2008-03-01 12:00:00', '2008-03-02 00:00:00' ];

# bad calls
eval { scalar call('generate_series(int,int)', 10, 19) };
like $@, qr/returned more than one row/;

# ====== multi-value (record) returning functions ======

@ary = call('pg_get_keywords()');
cmp_ok scalar @ary, '>', 200;
ok $row = $ary[0];
is ref $row, 'HASH';
ok exists $row->{word},    'should contain a word column';
ok exists $row->{catcode}, 'should contain a catcode column';
ok exists $row->{catdesc}, 'should contain a catdesc column';

# single-record
spi_exec_query(q{
	create or replace function f1(out r1 text, out r2 int) language plperl as $$
		return { r1=>10, r2=>11 };
	$$
});
@ary = PG->f1();
is scalar @ary, 1;
ok $row = $ary[0];
is $row->{r1}, 10;
is $row->{r2}, 11;
spi_exec_query('drop function f1()');

# multi-record
spi_exec_query(q{
	create or replace function f2() returns table (r1 text, r2 int) language plperl as $$
		return_next { r1 => $_, r2 => $_+1 } for 1..5;
		return undef;
	$$
});
@ary = PG->f2();
is scalar @ary, 5;
is $ary[-1]->{r1}, 5;
is $ary[-1]->{r2}, 6;
spi_exec_query('drop function f2()');

# ====== functions with defaults ======

spi_exec_query(q{
	create or replace function f3(int default 42) returns int language plperl as $$
		return shift() + 1;
	$$
});
is call('f3()'), 43;
spi_exec_query('drop function f3(int)');

# ====== functions with strange names ======

spi_exec_query(q{create or replace function "q 1"() returns int language plperl as 'return 42'});
is call('"q 1"'), 42;
spi_exec_query('drop function "q 1"()');

# ====== functions variadic args ======

spi_exec_query(q{
	create or replace function f4(VARIADIC numeric[]) returns float language plperlu as $$
		use PostgreSQL::PLPerl::Call;
		my $sum = 100;
		$sum += $_ for call('unnest(numeric[])', $_[0]);
		return $sum;
	$$
});
# call variadic with explicit number of args in the signature
is call('f4(numeric, numeric)',          10,11   ), 121;
is call('f4(numeric, numeric, numeric)', 10,11,12), 133;

# call variadic using '...' in the signature
is call('f4(numeric, numeric ...)',     10,11,12), 133;
is call('f4(numeric ...)',              10,11,12), 133;
is call('f4(numeric ...)',              10,11   ), 121;
is call('f4(numeric ...)',              10      ), 110;

spi_exec_query('drop function f4(variadic numeric[])');

# === finish up

$Test->_ending;
my $failed = grep { !$_ } Test::More->builder->summary;
warn "Test results:\n$test_output" if $failed;

return ($failed) ? "FAIL" : "PASS";

$func$;
