#!/usr/bin/perl

use strict;

print "1..4\n";
print "Running automated test suite for $0:\n\n";

use SyslogScan::Usage;
use SyslogScan::Summary;
use SyslogScan::ParseDate;
&SyslogScan::ParseDate::setDefaultYear(1996);


require "dumpvar.pl";

print "ok 1\n\n";

my $testRoot = "TestUsage";

my $testDir = "t";
chdir($testDir) || die "could not cd into testdir $testDir";

my $tmpDir = "tmp.$$";
my $testTmp = "$tmpDir/$testRoot.tmp";
my $testRef = "$testRoot.ref";
mkdir($tmpDir,0777) || die "could not create $tmpDir";
open(TEST,">$testTmp") || die "could not open $testTmp for write: $!";

$::gUsage = new SyslogScan::Usage();
$::gUsage -> registerSend(7);
$::gUsage -> registerReceive(15);
$::gUsage -> registerSend(100);

print "ok 2\n";

my $tmpStore = "$tmpDir/summary.store";

open(STORE_OUT,">$tmpStore");
$::gUsage -> persist(\*STORE_OUT);
close(STORE_OUT);

open(STORE_IN,"$tmpStore") or die "could not open $tmpStore";
$::gUsage2 = SyslogScan::Usage -> restore(\*STORE_IN);
close(STORE_IN);

$::gUsage3 = $::gUsage2 -> deepCopy();
$::gUsage3 -> registerSend(1500);

print "ok 3\n";

$^W = 0;

select(TEST);
print($::gUsage -> dump());
&dumpvar("","gUsage");
print($::gUsage2 -> dump());
&dumpvar("","gUsage2");
print($::gUsage3 -> dump());
&dumpvar("","gUsage3");
print "B: ", $::gUsage -> getBroadcastVolume -> dump(),
    " S: ", $::gUsage -> getSendVolume -> dump(),
    " R: ", $::gUsage -> getReceiveVolume -> dump(), "\n";
print "RM: ", $::gUsage -> getReceiveVolume -> getMessageCount(), "\n";
print "RB: ", $::gUsage -> getReceiveVolume -> getByteCount(), "\n";
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
