#
#	SQL::Preproc updatable cursor and stored procedure tests
#	requires DBD::Teradata
#
use strict;
use vars qw($testnum $loaded);
BEGIN { 
	my $tests = 10; 
	$^W= 1; 
	$| = 1; 
	eval {
		require DBD::Teradata;
	};
	print "1..0 # Skipped no DBD::Teradata\n" and
	exit 0
		if ($@);
	
	print "1..0 # Skipped no SQLPREPROC_DSN/USER/PASSWORD\n" and
	exit 0
		unless (defined($ENV{SQLPREPROC_DSN}) &&
			defined($ENV{SQLPREPROC_USER}) &&
			defined($ENV{SQLPREPROC_PASSWORD}));

	print "1..0 # Skipped no SQLPREPROC_DSN is not for Teradata\n" and
	exit 0
		unless ($ENV{SQLPREPROC_DSN}=~/^(dbi:)?Teradata:/);
	print "1..$tests\n";
}
END {print "not ok $testnum\n" unless $loaded;}

use SQL::Preproc
	emit => '09updcursor.pl',
	keepsql => 1,
	pponly => 1,
	alias => undef,
	relax => 1;

use DBI;
use DBI qw(:sql_types);
use SQL::Preproc::ExceptContainer;

$testnum = 1;
my $test_result;

my $ppctxt;

DECLARE CONTEXT $ppctxt;

print "ok $testnum declare context\n";

$testnum++;

CONNECT TO $ENV{SQLPREPROC_DSN} USER $ENV{SQLPREPROC_USER}
	IDENTIFIED BY $ENV{SQLPREPROC_PASSWORD}
	AS tdatconn
	WITH { tdat_mode => 'ANSI' };

print "ok $testnum Teradata connect\n";

$testnum++;

my $status = 1;
WHENEVER NOT FOUND { $status = undef; }

DECLARE CURSOR updcursor AS select * from sqlpp_csv for cursor;

print "ok $testnum declare updatable cursor\n";

$testnum++;

OPEN updcursor;

print "ok $testnum open updatable cursor\n";

$testnum++;

my $result = 'ok';
WHENEVER SQLERROR {
	my ($ctxt, $err, $errstr, $state) = @_;
	warn $errstr;
	$result = 'not ok';
}

my ($col1, $col2, $col3);
my $rowcount;
SELECT count(*) INTO :$rowcount FROM sqlpp_csv;

while ($status) {
	FETCH updcursor into :$col1, :$col2, :$col3;
	last unless $status;
	UPDATE sqlpp_csv set column2 = 'updated'
		WHERE CURRENT OF updcursor;
	last unless ($result eq 'ok');
}

my $updated;

if ($result == 'ok') {
SELECT count(*) INTO :$rowcount FROM sqlpp_csv
WHERE column2 = 'updated';

$result = ($updated == $rowcount) ? 'ok' : 'not ok';
print "$result $testnum fetch/update cursor\n";
}
else {
print "$result $testnum fetch/update cursor\n";
}
$testnum++;

$result = 'ok';
CLOSE updcursor;

print "$result $testnum close cursor\n";

$testnum++;
#
#	procedure tests
#
$result = 'ok';
EXECUTE IMMEDIATE <<'SQLPP_SP';
replace procedure sqlpp_sp(in parm1 int, inout parm2 int, out parm3 int)
begin
	set parm3 = parm1 + parm2;
	set parm2 = parm1 + 10;
end;
SQLPP_SP

print "$result $testnum replace procedure\n";

$testnum++;

$result = 'ok';
my ($parm1, $parm2, $outparm) = (10, 27, 0);
CALL sqlpp_sp(:$parm1, :$parm2, :outparm);

$result = (($result eq 'ok') && ($parm2 == 20) && ($outparm == 37)) ? 'ok' : 'not ok';
print "$result $testnum call procedure\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect\n";

$loaded = 1;
