#!/usr/bin/perl

use strict;

print "1..4\n";
print "Running automated test suite for $0:\n\n";

require "dumpvar.pl";
require "timelocal.pl";

print "ok 1\n\n";

my $testRoot = "read_mail_logTest";

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

my $start = timelocal(0,0,0,13,5,96);
my $end = timelocal(0,0,0,14,5,96);

my $cmd = "cd ..";
my $switch;
foreach $switch ("-u -U healthnet.org:NOT:time t/$goodLog",
		 "-g -U healthnet.org -T 6.13.96 t/$prevLog t/$goodLog",
		 "-m t/$prevLog t/$goodLog",
		 "-m -T $start..$end -o t/$tmpDir/cache.sto t/$prevLog t/$goodLog",
		 "-i t/$tmpDir/cache.sto")
{
    # $cmd .= " && $^X -d read_mail_log.pl -q -y 1996 $switch";
    $cmd .= " && $^X read_mail_log.pl -q -y 1996 $switch";
}

open(PROG,"$cmd |");

print "ok 2\n";

select(TEST);
while (<PROG>)
{
    print;
}
close(PROG);
($? >> 8) and die "read_mail_log.pl returned nonzero status";

close(TEST);

select(STDOUT);

print "ok 3\n";

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
    unlink("$tmpDir/cache.sto");
    unlink($testTmp);
    rmdir($tmpDir);
    print STDOUT "ok 4\n\n";
}
else
{
    print STDOUT "not ok 4\n\n";
}

exit $retval;
