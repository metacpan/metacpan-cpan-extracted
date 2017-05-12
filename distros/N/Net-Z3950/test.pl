# $Header: /home/cvsroot/NetZ3950/test.pl,v 1.12 2005/04/21 10:05:31 mike Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..23\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::Z3950;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;

# Test 1 was ability to load module

## ------------------------------ cut here ------------------------------

# For a similar test, run:
#	perl samples/simple.pl indexdata.dk 210 gils mineral


# Check that constants work
### This is vacuous now they're defined in Perl rather than C
if (Net::Z3950::Reason::EOF == 23951 &&
    Net::Z3950::Reason::Incomplete == 23952 &&
    Net::Z3950::Reason::Malformed == 23953 &&
    Net::Z3950::Reason::BadAPDU == 23954 &&
    Net::Z3950::Reason::Error == 23955) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

# Check that Net::Z3950::diagbib1_str() works
if (Net::Z3950::diagbib1_str(1) eq 'Permanent system error' &&
    Net::Z3950::diagbib1_str(2) eq 'Temporary system error' &&
    Net::Z3950::diagbib1_str(3) eq 'Unsupported search' &&
    Net::Z3950::diagbib1_str(28) eq 'Result set is in use') {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

# Create Net::Z3950 manager
my $mgr = new Net::Z3950::Manager(async => 1,
	smallSetUpperBound => 0, largeSetLowerBound => 10000,
	mediumSetPresentNumber => 5,
	preferredRecordSyntax => "GRS-1"
#	preferredRecordSyntax => "USMARC"
			     )
    or (print "not ok 4\n"), exit;
print "ok 4\n";

# Forge connection to the local "yaz-ztest" server
### You need to be connected to the internet for this to work, of course.
my $conn1 = $mgr->connect('bagel.indexdata.dk', 210)
    or (print "not ok 5 ($!)\n"), exit;
print "ok 5\n";

# no-op for historical reasons
print "ok 6\n";

# First init response
my $conn = $mgr->wait()
    or (print "not ok 7\n"), exit;
print "ok 7\n";

# Is the nominated connection one that we created?
check_connection(8, $conn);

# Which operation fired?  Should be an Init
check_op(9, $conn->op(), Net::Z3950::Op::Init);

# Was the connection accepted?
my $r = $conn->initResponse();
if (!$r->result()) {
    print "not ok 10\n";
    exit;
}
print "ok 10\n";

# We shouldn't really print this stuff if a test script.
if (0) {
    print "Connection accepted\n";
    print "referenceId: '", $r->referenceId(), "'\n";
    print "preferredMessageSize: '", $r->preferredMessageSize(), "'\n";
    print "maximumRecordSize: '", $r->maximumRecordSize(), "'\n";
    print "implementationId: '", $r->implementationId(), "'\n";
    print "implementationName: '", $r->implementationName(), "'\n";
    print "implementationVersion: '", $r->implementationVersion(), "'\n";
}

# No test -- currently this "just works"
# Amazingly, the GILS server supports neither 1=1 nor 1=21!
$conn1->option('databaseName', 'gils');
$conn1->startSearch(-prefix => '@or mineral machine');

# First search response
$conn = $mgr->wait()
    or (print "not ok 11\n"), exit;
print "ok 11\n";

# Is the nominated connection one that we created?
check_connection(12, $conn);

# Which operation fired?  Should be an Search
check_op(13, $conn->op(), Net::Z3950::Op::Search);

# Fetch result set
my $rs = $conn->resultSet()
    or error(14, $conn);
print "ok 14\n";

# No test -- this "just works"
my $size = $rs->size();

# We shouldn't really print this stuff if a test script.
if (0) {
    my $r = $rs->{searchResponse};
    print "referenceId: '", $r->referenceId(), "'\n";
    print "resultCount: '", $r->resultCount(), "'\n";
    print "numberOfRecordsReturned: '", $r->numberOfRecordsReturned(), "'\n";
    print "nextResultSetPosition: '", $r->nextResultSetPosition(), "'\n";
    print "searchStatus: '", $r->searchStatus(), "'\n";
    print "resultSetStatus: '", $r->resultSetStatus(), "'\n";
    print "presentStatus: '", $r->presentStatus(), "'\n";
    print "records: '", $r->records(), "'\n";
    if (0) {
	print "in detail: ";
	use Data::Dumper;
	print Dumper($r->records());
    }
}

my @seen = map { 0 } 0..$size;
my $nreq = 0;

my $rec;			# we want this visible after the loop exits
OUTER_LOOP: while (1) {
    # Test whether any elements of @tmp apart from 0'th are false
    {
	my @tmp = @seen;
	shift @tmp;
	last OUTER_LOOP if !grep { !$_ } @tmp;
    }

    for (my $i = 1; $i <= $size; $i++) {
	next if $seen[$i];

	$rec = $rs->record($i);
	if (defined $rec) {
	    # We shouldn't really print this stuff if a test script.
	    if (0) {
		print "\nRecord $i: ", $rec->render();
	    }
	    $seen[$i] = 1;
	} elsif ($rs->errcode() != 0) {
	    # The test suite will stop early here if you run it
	    # against the "ztest" server supplied with Yaz, after the
	    # 11th record of 17 in the result set.  This is due to
	    # ztest's somewhat idiosyncratic interpretation of what
	    # constitutes a seventeen-record result set.  Test against
	    # a real server instead.
	    die("can't fetch record $i of $size: " .
		"error code=" . $rs->errcode() .
		" [" . Net::Z3950::errstr($rs->errcode()) . "], " .
		"addinfo='". $rs->addinfo() . "'");
	} else {
	    # Record is not yet available -- we wait for requested
	    # records to arrive "every so often", say one in three.
	    next if ++$nreq < 3;
	    $conn = $mgr->wait();
	    die "oops -- expected Op::Get"
		if $conn->op() != Net::Z3950::Op::Get;
	    $nreq = 0;
	    next OUTER_LOOP;
	}
    }
}

### The following tests know details of the Zebra demo database
my $sq = $rs->subqueryCount();

$size == 18            and
$sq->{'mineral'} == 18 and
$sq->{'machine'} == 0
    or (print "not ok 15\n"), exit;
print "ok 15\n";

$rec->render() eq qq[6 fields:
(1,1) 1.2.840.10003.13.2
(1,14) "34"
(2,1) "MINERAL OCCURRENCES, DEPOSITS, PROSPECTS, AND MINES"
(4,52) "NEVADA BUREAU OF MINES AND GEOLOGY"
(4,1) "ESDD0048"
(1,16) "199101"
]
    or (print "not ok 16\nrec='", $rec->render(), "'\n"), exit;
print "ok 16\n";

# Testing scan
$conn->startScan('mineral');
$conn = $mgr->wait()
    or (print "not ok 17\n"), exit;
print "ok 17\n";

# Which operation fired?  Should be a Scan
check_op(18, $conn->op(), Net::Z3950::Op::Scan);
my $sr = $conn->scanResponse();

if ($sr->scanStatus() != 0 ||
    $sr->positionOfTerm() != 1 ||
    $sr->stepSize() != 0 ||
    $sr->numberOfEntriesReturned() != 20) {
    print "not ok 19\n";
    print "scanResponse APDU:\n";
    foreach my $key (sort keys %$sr) {
	print "$key -> $sr->{$key}\n";
    }
    exit;
}
print "ok 19\n";

my $term0 = $sr->entries()->[0]->termInfo();
my $term19 = $sr->entries()->[19]->termInfo();
if ($term0->term()->general() ne "mineral" ||
    $term0->globalOccurrences() != 18 ||
    $term19->term()->general() ne "national" ||
    $term19->globalOccurrences() != 2) {
    print "not ok 20\n";
    print "scanResponse entries:\n";
    foreach my $entry (@{$sr->entries()}) {
	foreach my $key (keys %{$entry}) {
	    print("\t", $entry->termInfo()->term()->general(),
		  " (" . $entry->termInfo()->globalOccurrences() . ")\n");
	}
    }
}
print "ok 20\n";

# Check scan's error-reporting
my $oldDB = $conn->option(databaseName => "nonExistentDB");
$conn->startScan('fruit');
$conn->option(databaseName => $oldDB);
$conn = $mgr->wait()
    or (print "not ok 21\n"), exit;
print "ok 21\n";

check_op(22, $conn->op(), Net::Z3950::Op::Scan);
my $sr = $conn->scanResponse();

if ($sr->scanStatus() != 6 ||
    $sr->diag()->condition() != 109 ||
    $sr->diag()->addinfo() ne "nonExistentDB") {
    print "not ok 23\n";
    { use Data::Dumper; print Dumper($sr); }
}
print "ok 23\n";

print "\ntests complete\n";
exit;


sub check_connection {
    my($testno, $conn) = @_;

    if ($conn != $conn1) {
	print "not ok $testno\n";
	exit 1;
    }

    print "ok $testno\n";
}


sub check_op {
    my($testno, $op, $wanted) = @_;

    if ($op != $wanted) {
	print "not ok $testno\n";
	exit 1;
    }

    print "ok $testno\n";
}


# Called on failure for test $testno; according to Perl-module test
# harness "best practice", this should just print "not ok $testno" and
# exit, but in Real Life(tm), we want any additional error information
# that's accrued in the connection object.
#
sub error {
    my($testno, $conn) = @_;

    print "not ok $testno\n";
    if ($conn->errcode()) {
	print("[error ", $conn->errcode(),
	      " (", Net::Z3950::diagbib1_str($conn->errcode()), ")",
	      " - ", $conn->addinfo(), "]\n");
    }
    exit 1;
}
