#
#	SQL::Preproc exception handler tests
#
use strict;
use vars qw($testnum $loaded);
BEGIN { my $tests = 13; $^W= 1; $| = 1; print "1..$tests\n"; }
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
#
#
#
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

my $errstatus;
my $nfstatus;
#
#	remember to put these inside some scope for testing
#
WHENEVER SQLERROR {
	my ($ctxt, $err, $state, $str) = @_;
	$errstatus = 
		(defined($ctxt) && ref $ctxt && (ref $ctxt eq 'HASH') &&
			(($dsn=~/^(dbi:)?CSV:/) || 
			(defined($err) && defined($state) && defined($str))));
}

print "ok $testnum WHENEVER SQLERROR OK\n";
$testnum++;

WHENEVER NOT FOUND {
	my $ctxt = shift;
	$nfstatus = (defined($ctxt) && ref $ctxt && (ref $ctxt eq 'HASH'));
}

print "ok $testnum WHENEVER NOT FOUND OK\n";
$testnum++;

my ($col1, $col2, $col3);
SELECT * INTO :$col1, :$col2, :$col3
FROM sqlpp_csv;

$test_result = ($col1 && $col2 && $col3 && (! $errstatus) && (! $nfstatus)) ? '' : 'not ';
print $test_result, "ok $testnum valid SELECT OK\n";

$testnum++;

($errstatus, $nfstatus) = (undef, undef);

EXEC SQL this is some gibberish to test bad sql;

$test_result = ($errstatus && (! $nfstatus)) ? '' : 'not ';
print $test_result, "ok $testnum catch bad sql error\n";

$testnum++;

($errstatus, $nfstatus) = (undef, undef);

DISCONNECT;

my %hashph1 = ();

SELECT * into :%hashph1	from sqlpp_csv;

$test_result = ($errstatus && (! $nfstatus)) ? '' : 'not ';
print $test_result, "ok $testnum catch no connection error\n";

$testnum++;

($errstatus, $nfstatus) = (undef, undef);

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

print "ok $testnum reconnect OK\n";
$testnum++;

{

	WHENEVER SQLERROR {
		my ($ctxt, $err, $state, $str) = @_;
		$errstatus = 'scoped exception'
			if (defined($ctxt) && ref $ctxt && (ref $ctxt eq 'HASH') &&
				(($dsn=~/^(dbi:)?CSV:/) || 
				(defined($err) && defined($state) && defined($str))));
	}

	print "ok $testnum scoped WHENEVER SQLERROR OK\n";
	$testnum++;

	OPEN unknown_cursor;

	$test_result = ($errstatus && ($errstatus eq 'scoped exception') &&
		(! $nfstatus)) ? '' : 'not ';
	print $test_result, "ok $testnum inner catch open of unknown cursor\n";

	$testnum++;
}

($errstatus, $nfstatus) = (undef, undef);

OPEN unknown_cursor;

$test_result = ($errstatus && ($errstatus ne 'scoped exception') &&
	(! $nfstatus)) ? '' : 'not ';
print $test_result, "ok $testnum outer catch open of unknown cursor\n";

$testnum++;

$test_result = 'not ok';
WHENEVER SQLERROR {
	my ($ctxt, $errno, $state, $msg) = @_;
	$test_result = 'ok';
}
RAISE SQLERROR (-1, 'S9999', 'Testing RAISE');

print "$test_result $testnum RAISEd exception\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect OK\n";

$loaded = 1;

