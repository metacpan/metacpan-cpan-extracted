#!/usr/bin/perl5

print "1..4\n";
print "Running automated test suite for $0:\n";
use SyslogScan::In_identdLine;
use SyslogScan::SendmailLine;
use SyslogScan::SyslogEntry;
require "dumpvar.pl";

use SyslogScan::ParseDate;
&SyslogScan::ParseDate::setDefaultYear(1996);

$::gbQuiet = 1;

print "ok 1\n\n";
#print STDERR "expect a 'no status field' message:\n";

$testRoot = "SyslogEntryTest";

$testDir = "t";
chdir($testDir) || die "could not cd into testdir $testDir";

$tmpDir = "tmp.$$";
$testTmp = "$tmpDir/$testRoot.tmp";
$testRef = "$testRoot.ref";
mkdir($tmpDir,0777) || die "could not create $tmpDir";
open(TEST,">$testTmp") || die "could not open $testTmp for write: $!";

$goodLog = "good_syslog";
$badLog = "bad_syslog";
$repLog = "repeat_syslog";

print STDOUT "testing error trapping...\n";
open(BAD,$badLog) || die "could not open $badLog";
$pLogLine = new SyslogScan::SyslogEntry \*BAD;

print STDOUT "ok 2\n\n";

print STDOUT "testing repetition processing...\n";

open(REP,$repLog) || die "could not open $repLog";
while ($pLogLine = new SyslogScan::SyslogEntry \*REP)
{
    last unless $pLogLine;
    die "unexpected content:  $$pLogLine{content}"
	unless ($$pLogLine{content} =~ /(\d+)times.rep/);

    $count = $1;
    $message = $$pLogLine{content};
    $seen{$message}++;
    if ($seen{$message} == 1)
    {
	# first time we saw this message
	die "undefined time" unless defined $$pLogLine{'time'};
	next;
    }
    if ($seen{$message} == $count)
    {
	# last time we should see this message
	die "undefined time" unless defined $$pLogLine{'time'};
	undef($seen{$message});
	next;
    }
    # intermediate instance of message, time should _not_
    # be defined since we do not know precisely when the
    # intermediate messages take place
    die "time defined, bye" if defined $$pLogLine{'time'};
}

foreach (keys %seen)
{
    die "did not see proper count for $_"
	if (defined $seen{$_} and $seen{$_} > 0);
 }

print "ok 3\n";

open(GOOD,$goodLog) || die "could not open $goodLog";

@gLogLineList = ();
while ($pLogLine = new SyslogScan::SyslogEntry \*GOOD)
{
    last unless $pLogLine;
    push (@gLogLineList, $pLogLine);
}

$^W = 0;

select(TEST);
&dumpvar("","gLogLineList");
close(TEST);
select(STDOUT);

$retval =
    system("perl -pi.bak -e 's/(HASH|ARRAY|unix_time).+/\$1/g' $testTmp") >> 8;

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
