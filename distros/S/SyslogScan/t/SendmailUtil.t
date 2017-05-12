#!/usr/bin/perl5

$::gbQuiet = 1;

print "1..2\n";
print "Running automated test suite for $0:\n\n";

use SyslogScan::SendmailUtil;
use SyslogScan::ParseDate;
&SyslogScan::ParseDate::setDefaultYear(1996);

require "dumpvar.pl";

print "ok 1\n\n";
$testRoot = "SendmailUtilTest";

$testDir = "t";
chdir($testDir) || die "could not cd into testdir $testDir";

$tmpDir = "tmp.$$";
$testTmp = "$tmpDir/$testRoot.tmp";
$testRef = "$testRoot.ref";
mkdir($tmpDir,0777) || die "could not create $tmpDir";
open(TEST,">$testTmp") || die "could not open $testTmp for write: $!";
select(TEST);

$goodLog = "good_syslog";
open(GOOD,$goodLog) || die "could not open $goodLog";

@gLogLineList = ();
while ($pLogLine = &SyslogScan::SendmailUtil::getNextMailTransfer(\*GOOD))
{
    my $myRef = ref $pLogLine;
    die "unexpected reference $myRef returned by getNextMailTransfer"
	unless (($myRef eq "SyslogScan::SendmailLineTo") ||
		($myRef eq "SyslogScan::SendmailLineFrom") ||
		($myRef eq "SyslogScan::SendmailLineClone"));
    push (@gLogLineList, $pLogLine);
}

$^W = 0;

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
    print STDOUT "ok 2\n\n";
}
else
{
    print STDOUT "not ok 2\n\n";
}

exit $retval;
