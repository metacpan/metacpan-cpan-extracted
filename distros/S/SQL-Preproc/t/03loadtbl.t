use strict;
use vars qw($testnum $loaded);
BEGIN { my $tests = 10; $^W= 1; $| = 1; print "1..$tests\n"; }
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

my $use_csv = ($dsn=~/^(dbi:)?CSV:/);

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

INSERT INTO sqlpp_csv VALUES(1, 'the first row', 'abcdefghij');

print "ok $testnum INSERT OK\n";

$testnum++;

my ($ph1, $ph2, $ph3) = (2, 'the second row', 'zyxwvutsrqpo');
INSERT INTO sqlpp_csv VALUES(:$ph1, :$ph2, :$ph3);

print "ok $testnum INSERT scalar phs OK\n";

$testnum++;

my @aryph1 = (3,4,5,6,7,8,9,10);
my @aryph2 = (
	'the third row',
	'the fourth row',
	'the fifth row',
	'the sixth row',
	'the seventh row',
	'the eighth row',
	'the ninth row',
	'the tenth row',
);
my @aryph3 = (
	'abcdefghijklmnop',
	'qrstuvwxyz',
	'1234567890',
	'dfgaragsdsdffgd',
	'adsfasdfagsdfgsgh',
	'33333333333333333333333333',
	'00000000000000000000',
	'mmmmmmmmmmmmmmmmmmmm',
);
#
#	skip array binding for teradata for now
#
if ($dsn=~/^(dbi:)?Teradata:/) {
	print "ok $testnum # Skipped INSERT array tests (incomplete DBD::Teradata support)\n";
print STDERR "Skipping INSERT array\n";
}
else {

EXEC SQL insert into sqlpp_csv values(:@aryph1, :@aryph2, :@aryph3);

print "ok $testnum INSERT array phs OK\n";
}
$testnum++;

my $insimm = "INSERT INTO sqlpp_csv VALUES(11, 'the eleventh row', 'abcdefghij')";

EXECUTE IMMEDIATE $insimm;

print "ok $testnum EXECUTE IMMEDIATE INSERT OK\n";

$testnum++;

@aryph1 = (13,14,15,16,17,18,19,20);
@aryph2 = (
	'the thirteenth row',
	'the fourteenth row',
	'the fifteenth row',
	'the sixteenth row',
	'the seventeenth row',
	'the eighteenth row',
	'the ninteenth row',
	'the twentyth row',
);
@aryph3 = (
	'abcdefghijklmnop',
	'qrstuvwxyz',
	'1234567890',
	'dfgaragsdsdffgd',
	'adsfasdfagsdfgsgh',
	'33333333333333333333333333',
	'00000000000000000000',
	'mmmmmmmmmmmmmmmmmmmm',
);

PREPARE ins_csv as insert into sqlpp_csv values(:$ph1, :$ph2, :$ph3);

#
#	unfortunately, DBD::CSV doesn't support xactions
unless ($use_csv) {
BEGIN WORK;
}
foreach (0..$#aryph1) {
	$ph1 = shift @aryph1;
	$ph2 = shift @aryph2;
	$ph3 = shift @aryph3;
	EXECUTE ins_csv;
}

unless ($use_csv) {
ROLLBACK WORK;
}
print "ok $testnum PREPARED INSERT phs + rollback OK\n";

$testnum++;

@aryph1 = (13,14,15,16,17,18,19,20);
@aryph2 = (
	'the thirteenth row',
	'the fourteenth row',
	'the fifteenth row',
	'the sixteenth row',
	'the seventeenth row',
	'the eighteenth row',
	'the ninteenth row',
	'the twentyth row',
);
@aryph3 = (
	'abcdefghijklmnop',
	'qrstuvwxyz',
	'1234567890',
	'dfgaragsdsdffgd',
	'adsfasdfagsdfgsgh',
	'33333333333333333333333333',
	'00000000000000000000',
	'mmmmmmmmmmmmmmmmmmmm',
);

#
#	unfortunately, DBD::CSV doesn't support xactions
unless ($use_csv) {
BEGIN WORK;
}

foreach (0..$#aryph1) {
	$ph1 = shift @aryph1;
	$ph2 = shift @aryph2;
	$ph3 = shift @aryph3;
	EXECUTE ins_csv;
}

unless ($use_csv) {
COMMIT WORK;
}

print "ok $testnum PREPARED INSERT phs + commit OK\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect OK\n";

$loaded = 1;

