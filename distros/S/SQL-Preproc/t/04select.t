use strict;
use vars qw($testnum $loaded);
BEGIN { my $tests = 8; $^W= 1; $| = 1; print "1..$tests\n"; }
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

my ($col1, $col2, $col3);
SELECT * INTO :$col1, :$col2, :$col3
FROM sqlpp_csv;

$test_result = ($col1 && $col2 && $col3) ? '' : 'not ';
print $test_result, "ok $testnum single SELECT OK\n";

$testnum++;

SELECT * FROM sqlpp_csv;

$test_result = ($_[0] && $_[1] && $_[2]) ? '' : 'not ';
print $test_result, "ok $testnum default SELECT OK\n";

$testnum++;

my @aryph1 = ();

EXEC SQL 
	select * into :@aryph1
	from sqlpp_csv;

$test_result = (scalar @aryph1) ? '' : 'not ';
print $test_result, "ok $testnum bulk array SELECT OK\n";

$testnum++;

my %hashph1 = ();

SELECT * into :%hashph1	from sqlpp_csv;

$test_result = (scalar keys %hashph1) ? '' : 'not ';
print $test_result, "ok $testnum bulk hash SELECT OK\n";

$testnum++;

my $inph = '10';
SELECT * into :@aryph1
	from sqlpp_csv
	where column1 > :$inph;

$test_result = (scalar @aryph1) ? '' : 'not ';
print $test_result, "ok $testnum bulk array SELECT w/ in phs OK\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect OK\n";

$loaded = 1;

