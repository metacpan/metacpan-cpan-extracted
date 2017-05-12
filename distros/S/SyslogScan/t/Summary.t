#!/usr/bin/perl

use strict;

print "1..4\n";
print "Running automated test suite for $0:\n\n";

use SyslogScan::Summary;
use SyslogScan::DeliveryIterator;
use SyslogScan::ParseDate;
&SyslogScan::ParseDate::setDefaultYear(1996);


require "dumpvar.pl";

$::gbQuiet = 1;

print "ok 1\n\n";

my $testRoot = "SummaryTest";

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
		 'syslogList' => [$prevLog,$goodLog],
	         'unknownSize' => 0,
	         'defaultYear' => 1996 };

my $iter;
my $delivery;

$iter = new SyslogScan::DeliveryIterator %$pIterOpt;

$::gSummary = new SyslogScan::Summary();
while ($delivery = $iter -> next)
{
    $::gSummary -> registerDelivery($delivery);
}

$iter = new SyslogScan::DeliveryIterator %$pIterOpt;
$::gSummary1 = new SyslogScan::Summary($iter);

print "ok 2\n";

my $tmpStore = "$tmpDir/summary.store";

open(STORE_OUT,">$tmpStore");
$::gSummary -> persist(\*STORE_OUT);
close(STORE_OUT);

open(STORE_IN,"$tmpStore") or die "could not open $tmpStore";
$::gSummary2 = SyslogScan::Summary -> restore(\*STORE_IN);
close(STORE_IN);
$::gSummary2 -> addSummary($::gSummary);

my $iter1 = new SyslogScan::DeliveryIterator %$pIterOpt;
my $iter2 = new SyslogScan::DeliveryIterator %$pIterOpt;
$::gSummary3 = new SyslogScan::Summary();
# all mail from unique3 but not to hello.com
$::gSummary3 -> registerAllInIterators('unique3','^(?!.*hello\.com$)',$iter1,$iter2);

print "ok 3\n";

$^W = 0;

select(TEST);
print($::gSummary -> dump());
&dumpvar("","gSummary");
print($::gSummary1 -> dump());
&dumpvar("","gSummary1");
print($::gSummary2 -> dump());
&dumpvar("","gSummary2");
print($::gSummary3 -> dump());
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
    unlink($tmpStore);
    rmdir($tmpDir);
    print STDOUT "ok 4\n\n";
}
else
{
    print STDOUT "not ok 4\n\n";
}

exit $retval;
