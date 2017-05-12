use strict;
use vars qw($testnum $loaded);
BEGIN { my $tests = 15; $^W= 1; $| = 1; print "1..$tests\n"; }
END {print "not ok $testnum\n" unless $loaded;}

use SQL::Preproc;

use DBI;
use DBI qw(:sql_types);
use SQL::Preproc::ExceptContainer;

$testnum = 1;

my $ppctxt;

DECLARE CONTEXT $ppctxt;

print "ok $testnum declare context OK\n";

$testnum++;

my $dsn = $ENV{SQLPREPROC_DSN} ||= 'CSV:csv_sep_char=\\;';
my $user = $ENV{SQLPREPROC_USER};
my $password = $ENV{SQLPREPROC_PASSWORD};

if (defined($user)) {
	if (defined($password)) {
		CONNECT TO $dsn USER $user
			IDENTIFIED BY $password
			AS csvconn;
	}
	else {
		CONNECT TO $dsn USER $user AS csvconn;
	}
}
else {
	CONNECT TO $dsn AS csvconn;
}

print "ok $testnum qualified connect OK\n";

$testnum++;

CREATE TABLE sqlpp_csv (
column1 integer,
column2 varchar(30),
column3 char(24)
);

print "ok $testnum create table OK\n";

$testnum++;

DROP TABLE sqlpp_csv;

print "ok $testnum drop table OK\n";

$testnum++;

EXEC SQL create table sqlpp_csv (
column1 integer,
column2 varchar(30),
column3 char(24)
);

print "ok $testnum EXEC SQL create table OK\n";

$testnum++;

EXEC SQL Drop Table sqlpp_csv;

print "ok $testnum EXEC SQL drop table OK\n";

$testnum++;

EXECUTE IMMEDIATE 'create table sqlpp_csv (
column1 integer,
column2 varchar(30),
column3 char(24)
)';

print "ok $testnum EXECUTE IMMEDIATE create table OK\n";

$testnum++;

EXECUTE IMMEDIATE <<'HEREDOC';
drop table 
	sqlpp_csv
HEREDOC

print "ok $testnum EXECUTE IMMEDIATE w/ heredoc OK\n";

$testnum++;

my $sql = 'create table sqlpp_csv (
column1 integer,
column2 varchar(30),
column3 char(24)
)';
EXECUTE IMMEDIATE $sql;

print "ok $testnum EXECUTE IMMEDIATE expression OK\n";

$testnum++;

EXEC SQL drop table sqlpp_csv;

print "ok $testnum exec sql OK\n";

$testnum++;

PREPARE createtbl AS create table sqlpp_csv (
column1 integer,
column2 varchar(30),
column3 char(24)
);

print "ok $testnum PREPARE create table OK\n";

$testnum++;

EXEC SQL prepare droptbl as Drop Table sqlpp_csv;

print "ok $testnum EXEC SQL PREPARE drop table OK\n";

$testnum++;

EXECUTE createtbl;

print "ok $testnum EXECUTE prepared create table OK\n";

$testnum++;

EXEC SQL execute droptbl;

print "ok $testnum EXEC SQL execute drop table OK\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect OK\n";

$loaded = 1;

