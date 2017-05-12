#!/usr/bin/perl

use strict;

print "1..4\n";
print "Running automated test suite for $0:\n\n";

use SyslogScan::ByGroup;
use SyslogScan::Summary;
use SyslogScan::DeliveryIterator;
use SyslogScan::ParseDate;
&SyslogScan::ParseDate::setDefaultYear(1996);


$::gbQuiet = 1;

require "dumpvar.pl";

print "ok 1\n\n";

my $testRoot = "ByGroupTest";

#print STDERR "Expect a 'could not find sender' message:\n";

my $testDir = "t";
chdir($testDir) || die "could not cd into testdir $testDir";

my $tmpDir = "tmp.$$";
my $testTmp = "$tmpDir/$testRoot.tmp";
my $testRef = "$testRoot.ref";
mkdir($tmpDir,0777) || die "could not create $tmpDir";
open(TEST,">$testTmp") || die "could not open $testTmp for write: $!";

my $goodLog = "good_syslog";
my $prevLog = "prev_syslog";

my $pIterOpt = { 'startDate' => 'Jun 13 1996 02:00:00',
		 'endDate' => 'Jun 13 1996 09:00:00',
	         'unknownSender' => 'antiquity',
	         'unknownSize' => 0,
	         'defaultYear' => 1996 };

$::gSummary = new SyslogScan::Summary();

my $iter;
my $delivery;

open(PREV,$prevLog) || die "could not open $prevLog";
$iter = new SyslogScan::DeliveryIterator %$pIterOpt;
while ($delivery = $iter -> next(\*PREV))
{
    $::gSummary -> registerDelivery($delivery);
}
open(GOOD,$goodLog) || die "could not open $goodLog";
while ($delivery = $iter -> next(\*GOOD))
{
    $::gSummary -> registerDelivery($delivery);
}

print "ok 2\n";

$::gByGroup = new SyslogScan::ByGroup($::gSummary);

print "ok 3\n";

$^W = 0;

select(TEST);
&dumpvar("","gByGroup");
print($::gByGroup -> dump());
close(TEST);

select(STDOUT);

my $retval =
    system("perl -pi.bak -e 's/(HASH|ARRAY).+/\$1/g' $testTmp") >> 8;

if (! $retval)
{
    $retval = system("diff $testRef $testTmp") >> 8;
}

if (! $retval)
{
    print STDOUT "$0 produces same variable dump as expected.\n";
    unlink("$testTmp.bak");
    unlink($testTmp);
    rmdir($tmpDir);
    print STDOUT "ok 4\n\n";
}
else
{
    print STDOUT "not ok 4\n\n";
}

exit $retval;
