#
#	SQL::Preproc syntax extension module tests
#	requires DBD::Teradata and SQL::Preproc::Teradata
#
use strict;
use vars qw($testnum $loaded);
BEGIN { 
	my $tests = 6; 
	$^W= 1; 
	$| = 1; 
	eval {
		require DBD::Teradata;
	};
	print "1..0 # Skipped: no DBD::Teradata\n" and
	exit 0
		if ($@);
	eval {
		require SQL::Preproc::Teradata;
	};
	print "1..0 # Skipped: no SQL::Preproc::Teradata\n" and
	exit 0
		if ($@);
	
	print "1..0 # Skipped: no SQLPREPROC_DSN/USER/PASSWORD\n" and
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
	syntax => [ 'Teradata' ];

use DBI;
use DBI qw(:sql_types);
use SQL::Preproc::ExceptContainer;

$testnum = 1;
my $test_result;

my $ppctxt;

DECLARE CONTEXT $ppctxt;

print "ok $testnum declare context OK\n";

$testnum++;

CONNECT TO "Teradata:$ENV{SQLPREPROC_DSN}" USER $ENV{SQLPREPROC_USER}
	IDENTIFIED BY $ENV{SQLPREPROC_PASSWORD}
	AS tdatconn WITH tdat_utility => 'MONITOR';

print "ok $testnum Teradata connect OK\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect OK\n";

$loaded = 1;

