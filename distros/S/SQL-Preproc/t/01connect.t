use strict;
use vars qw($testnum $loaded);
BEGIN { my $tests = 7; $^W= 1; $| = 1; print "1..$tests\n"; }
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

print "ok $testnum connect OK\n";

$testnum++;

DISCONNECT csvconn;

print "ok $testnum disconnect OK\n";

$testnum++;

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

print "ok $testnum connect OK\n";

$testnum++;

DISCONNECT ALL;

print "ok $testnum disconnect ALL OK\n";

$testnum++;

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

print "ok $testnum default connect OK\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect OK\n";

$loaded = 1;

