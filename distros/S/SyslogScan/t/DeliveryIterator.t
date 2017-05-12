#!/usr/bin/perl

use strict;

print "1..6\n";
print "Running automated test suite for $0:\n\n";

use SyslogScan::DeliveryIterator;
use SyslogScan::ParseDate;
&SyslogScan::ParseDate::setDefaultYear(1996);

require "dumpvar.pl";
@$::gpDeliveryList = ();
@::gDeliveryLol = ();

$::gbQuiet = 1;

my (%gSeenType, %gTypeCount, %gSeenIt);


sub allowType
{
    my ($address, @legalType) = @_;
    my ($user, $type) = ($address =~ /(.+)\@([^\.]+)\.+/);
    $type =~ tr/A-Z/a-z/;
    $user =~ tr/A-Z/a-z/;
    die "could not parse type from address $address"
	unless defined $type;
    die "illegal type $type from address $address"
	unless grep ($_ eq $type, @legalType);
    $gSeenType{$type}++;
    #print STDERR "user is $user\n";
    if ($user =~ /^\<?(...)?count(\d+)\>?$/)
    {
	$gTypeCount{$type} = $2;
	print "expecting $2 of $type\n";
    }
    #print STDERR "message type is $type\n";
    return $type;
}

sub checkTypeCount
{
    my (@typeToCheck) = @_;
    my $type;
    foreach $type (@typeToCheck)
    {
	die "never saw message of type $type"
	    unless $gSeenType{$type};
	die "saw $gSeenType{$type}, expected $gTypeCount{$type} of $type"
	    unless ($gSeenType{$type} == $gTypeCount{$type});
	print "found $gSeenType{$type} $type messages\n";
    }
    # &dumpvar("","gDeliveryList");
    push (@::gDeliveryLol, $::gpDeliveryList);
    # &dumpvar("","gDeliveryLol");
    # print "undefining\n";
    undef $::gpDeliveryList;
    # &dumpvar("","gDeliveryLol");
    undef %gTypeCount;
    undef %gSeenType;
    undef %gSeenIt;
}

sub checkDelivery
{
    $::myDelivery = shift;
    my @legalList = @_;

    my ($from, $pToList, $to, $instance);
    my ($fromSub, $type);

    #&dumpvar("","myDelivery");
    ($from, $pToList, $instance) = ($$::myDelivery{Sender},
				    $$::myDelivery{ReceiverList},
				    $$::myDelivery{Instance});
    die "instance not defined" unless defined($instance);
    defined ($from) || die "no from defined";
    defined ($pToList) || die "no pToList defined";
    defined ($$pToList[0]) || die "pToList is empty";

    if ($from =~ /^.?unique/i)
    {
	$gSeenIt{$from}++;
	($gSeenIt{$from} eq $instance) ||
	    die "$gSeenIt{$from} for $from does not match instance $instance";
    }
    else
    {
	die "unexpected multiple instance from $from"
	    unless $instance == 1;
    }

    $fromSub = substr($from,0,3);
    foreach $to (@$pToList)
    {
	$type = &allowType($to,@legalList);
	if ($type eq 'prev')
	{
	    (($from =~ /antiquity/i) xor $::gResolvePrev)
		|| die "error:  prev from $from to $to resolv $::gResolvePrev";
	}
	($to =~ /$fromSub/i) ||
	    ($from =~ /antiquity/i && $to =~ /count/i) ||
		die "from $from does not match to $to";
    }
    push (@$::gpDeliveryList, $::myDelivery);
}

print "ok 1\n\n";
my $testRoot = "DeliveryIteratorTest";

#print STDERR "Expect some 'could not find sender' messages:\n";

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

my $iter;

open(GOOD,$goodLog) || die "could not open $goodLog";
$iter = new SyslogScan::DeliveryIterator %$pIterOpt;
while ($::delivery = $iter -> next(\*GOOD))
{
    &checkDelivery($::delivery,"ok","ant","prev");
}
&checkTypeCount("ok","ant","prev");

print "\nok 2\n";

$iter = new SyslogScan::DeliveryIterator ( 'startDate' =>
					       'Jun 13 1996 02:00:00',
					       'endDate' =>
						   'Jun 13 1996 09:00:00',
					       'syslogList' =>
					       [$goodLog],
					  'unknownSender' => 'antiquity',
					  'unknownSize' => 0,
					  'defaultYear' => 1996);
while ($::delivery = $iter -> next)
{
    &checkDelivery($::delivery,"ok","ant","prev");
}
&checkTypeCount("ok","ant","prev");

print "\nok 3\n";

open(GOOD,$goodLog) || die "could not open $goodLog";
$iter = new SyslogScan::DeliveryIterator ( 'startDate' =>
					       'Jun 13 1996 02:00:00',
					       'endDate' =>
						   'Jun 13 1996 09:00:00',
					       'syslogList' =>
					  ["whoops"],
					  'unknownSender' => 'antiquity',
					  'unknownSize' => 0,
					  'defaultYear' => 1996 );
while ($::delivery = $iter -> next(\*GOOD))
{
    open(STORE_OUT,">$tmpDir/store.txt");
    $::delivery -> persist(\*STORE_OUT);
    close(STORE_OUT);
    open(STORE_IN,"$tmpDir/store.txt");
    $::delivery = SyslogScan::Delivery -> restore(\*STORE_IN);
    close(STORE_IN);
    &checkDelivery($::delivery,"ok","ant","prev");
}
&checkTypeCount("ok","ant","prev");

print "\nok 4\n";

$::gResolvePrev = 1;
open(GOOD,$goodLog) || die "could not open $goodLog";
open(PREV,$prevLog) || die "could not open $prevLog";
$iter = new SyslogScan::DeliveryIterator %$pIterOpt;
while ($::delivery = $iter -> next(\*PREV))
{
    &checkDelivery($::delivery,"ok","ant","prev");
}

$::gTestDump = "";
while ($::delivery = $iter -> next(\*GOOD))
{
    &checkDelivery($::delivery,"ok","ant","prev");
    $::gTestDump .= $::delivery -> summary();
    $::gTestDump .= $::delivery -> dump();
}
&checkTypeCount("ok","ant","prev");
undef($::gResolvePrev);

print "\nok 5\n";

$^W = 0;

select(TEST);
&dumpvar("","gDeliveryLol");
&dumpvar("","gTestDump");
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
    unlink("$tmpDir/store.txt");
    unlink("$testTmp.bak");
    unlink($testTmp);
    rmdir($tmpDir);
    print STDOUT "ok 6\n\n";
}
else
{
    print STDOUT "not ok 6\n\n";
}

exit $retval;
