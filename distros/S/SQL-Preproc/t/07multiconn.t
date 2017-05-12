#
#	SQL::Preproc multi-connection tests
#
use strict;
use vars qw($testnum $loaded);
BEGIN { my $tests = 11; $^W= 1; $| = 1; print "1..$tests\n"; }
END {print "not ok $testnum\n" unless $loaded;}

use SQL::Preproc;

use DBI;
use DBI qw(:sql_types);
use SQL::Preproc::ExceptContainer;

$testnum = 1;
my $test_result;

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
			AS first_conn;
	}
	else {
		CONNECT TO $dsn USER $user AS first_conn;
	}
}
else {
	CONNECT TO $dsn AS first_conn;
}

print "ok $testnum qualified connect OK\n";

$testnum++;

if (defined($user)) {
	if (defined($password)) {
		CONNECT TO $dsn USER $user
			IDENTIFIED BY $password
			AS second_conn;
	}
	else {
		CONNECT TO $dsn USER $user AS second_conn;
	}
}
else {
	CONNECT TO $dsn AS second_conn;
}

print "ok $testnum qualified connect OK\n";

$testnum++;

SET CONNECTION first_conn;

print "ok $testnum set connect OK\n";

$testnum++;

my ($col1, $col2, $col3);
SELECT * INTO :$col1, :$col2, :$col3
FROM sqlpp_csv;

$test_result = ($col1 && $col2 && $col3) ? '' : 'not ';
print $test_result, "ok $testnum single SELECT OK\n";

$testnum++;

SET CONNECTION second_conn;

print "ok $testnum another set connect OK\n";

$testnum++;

SELECT * FROM sqlpp_csv;

$test_result = ($_[0] && $_[1] && $_[2]) ? '' : 'not ';
print $test_result, "ok $testnum default SELECT OK\n";

$testnum++;

DISCONNECT second_conn;

print "ok $testnum explicit disconnect OK\n";

$testnum++;

SET CONNECTION first_conn;

print "ok $testnum set connect after disconnect OK\n";

$testnum++;

($col1, $col2, $col3) = (undef, undef, undef);
SELECT * INTO :$col1, :$col2, :$col3
FROM sqlpp_csv;

$test_result = ($col1 && $col2 && $col3) ? '' : 'not ';
print $test_result, "ok $testnum single SELECT OK\n";

$testnum++;

DISCONNECT ALL;

print "ok $testnum disconnect ALL OK\n";

$loaded = 1;

