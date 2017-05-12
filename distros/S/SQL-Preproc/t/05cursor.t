#
#	SQL::Preproc test readonly cursors
#
use strict;
use vars qw($testnum $loaded);
BEGIN { my $tests = 17; $^W= 1; $| = 1; print "1..$tests\n"; }
END {print "not ok $testnum\n" unless $loaded;}

use SQL::Preproc
	relax => 1;

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

DECLARE CURSOR mycursor AS 
	SELECT * FROM sqlpp_csv;

print "ok $testnum declare cursor OK\n";

$testnum++;

OPEN mycursor;

print "ok $testnum open cursor OK\n";

$testnum++;

if ($dsn=~/^(dbi:)?CSV:/) {
	print "ok 5 # Skipped DESCRIBE tests (CSV lacks full metadata)\n";
	print "ok 6 # Skipped DESCRIBE tests (CSV lacks full metadata)\n";
	print "ok 7 # Skipped DESCRIBE tests (CSV lacks full metadata)\n";
print STDERR "Skipping describes\n";
	$testnum += 3;
}
else {
my $meta;
DESCRIBE mycursor into :$meta;

unless ($meta && ref $meta && (ref $meta eq 'ARRAY') &&
	(scalar @$meta == 3)) {
print "not ok $testnum DESCRIBE INTO scalar\n";
}
else {
	my $i = 0;
	foreach (@$meta) {
		$i++ if ($_->{Name} && $_->{Type})
	}
	($i == 3) ? print "ok $testnum DESCRIBE INTO scalar\n" :
		print "not ok $testnum DESCRIBE INTO scalar\n";
}

$testnum++;

my @meta;
DESCRIBE mycursor into :@meta;

unless (scalar @$meta == 3) {
print "not ok $testnum DESCRIBE INTO array\n";
}
else {
	my $i = 0;
	foreach (@meta) {
		$i++ if ($_->{Name} && $_->{Type})
	}
	($i == 3) ? print "ok $testnum DESCRIBE INTO scalar\n" :
		print "not ok $testnum DESCRIBE INTO scalar\n";
}

$testnum++;

my %meta;
DESCRIBE mycursor into :%meta;

unless (scalar keys %meta == 3) {
print "not ok $testnum DESCRIBE INTO array\n";
}
else {
	my $i = 0;
	foreach (keys %meta) {
		$i++ if $meta{$_}->{Type};
	}
	($i == 3) ? print "ok $testnum DESCRIBE INTO scalar\n" :
		print "not ok $testnum DESCRIBE INTO scalar\n";
}

$testnum++;
}

FETCH mycursor;

$test_result = (scalar @_) ? '' : 'not ';
print $test_result, "ok $testnum default FETCH OK\n";

$testnum++;

FETCH mycursor INTO :$col1, :$col2, :$col3;

$test_result = (defined($col1) && defined($col2) && defined($col3)) ? '' : 'not ';
print $test_result, "ok $testnum scalar FETCH OK\n";

$testnum++;

my @aryph;
FETCH mycursor INTO :@aryph;

$test_result = (scalar @aryph) ? '' : 'not ';
print $test_result, "ok $testnum array FETCH OK\n";

$testnum++;

my %hashph = ();

FETCH mycursor INTO :%hashph;

$test_result = (scalar keys %hashph) ? '' : 'not ';
print $test_result, "ok $testnum hash FETCH OK\n";

$testnum++;

my $status = 1;
WHENEVER NOT FOUND { $status = undef; }

while ($status) {
	FETCH mycursor;
}

print "ok $testnum FETCH to NOT FOUND OK\n";

$testnum++;

CLOSE mycursor;

print "ok $testnum CLOSE cursor OK\n";

$testnum++;

OPEN mycursor;

print "ok $testnum reOPEN cursor OK\n";

$testnum++;

$status = 1;
my $result = pass_ctxt($ppctxt) ? 'ok' : 'not ok';

print "$result $testnum Passed context OK\n";

$testnum++;

CLOSE mycursor;

print "ok $testnum reCLOSE cursor OK\n";

$testnum++;

DISCONNECT;

print "ok $testnum default disconnect OK\n";

$loaded = 1;

#
#	test passing our context to subroutines,
#	and invoking a handler
#
sub pass_ctxt {
	my ($ctxt) = @_;
	
	DECLARE CONTEXT $ctxt;
	my $rows = 0;
	while ($status) {
		FETCH mycursor;
		last unless $status;
		return undef unless (scalar @_ == 3);
		$rows++;
	}
	return $rows;
}
