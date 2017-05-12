#! /usr/bin/perl -w
#*********************************************************************
#*** t/20LBOptions.t
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 20LBOptions.t,v 1.3 2009-11-25 11:00:10 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Factory;
use ResourcePool::LoadBalancer;

BEGIN {
	eval "use Time::HiRes qw(time)";
}

sub timeinframe($$) {
	my ($is, $should) = @_;
	my ($low, $high);

	if (exists $INC{"Time/HiRes.pm"}) {
		($low, $high) = (($should - 0.2), ($should + 0.5));
	} else {
		($low, $high) = (($should - 1), ($should + 1));
	}
	if ( ($low <= $is) && ($is <= $high)) {
		return 1;
	} else {
		printf(STDERR "# Time test faild: (expected %ss, got %ss)\n", $should, $is);
		return 0;
	}
}

BEGIN { plan tests => 39; };

# there shall be silence
$SIG{'__WARN__'} = sub {};

my $f1 = ResourcePool::Factory->new('f1');
my $f2 = ResourcePool::Factory->new('f2');
my $f3 = ResourcePool::Factory->new('f3');
my $f4 = ResourcePool::Factory->new('f4');
my $f5 = ResourcePool::Factory->new('f5');
my $f6 = ResourcePool::Factory->new('f6');

ok ((defined $f1) && (defined $f2) && (defined $f3) && (defined $f4) && (defined $f5) && (defined $f6));

my $p1 = ResourcePool->new($f1, MaxTry => 5);
my $lb1 = ResourcePool::LoadBalancer->new('lb1', MaxTry => 3);
ok ((defined $p1) && (defined $lb1));
$lb1->add_pool($p1);

my ($r1, $r2, $r3, $r4, $r5, $r6);
my ($start, $stop);

$r1 = $lb1->get();
ok (defined $r1);

ok ($lb1->free($r1));
ok (! $lb1->free($r1)); # double free
ok ($f1->_my_very_private_and_secret_test_hook() == 1);

$r1->_my_very_private_and_secret_test_hook(0); # invalidate resource
ok !($r1->precheck());

$start = time();
$r2 = $lb1->get();
$stop = time();
ok ($r1 != $r2); # a new resource
ok timeinframe(($stop - $start), 0); # no sleep has been done
ok ($f1->_my_very_private_and_secret_test_hook() == 2); # facotry has been used twice

$r2->_my_very_private_and_secret_test_hook(0);  # invalidate resource

ok ($lb1->free($r2));
ok ($f1->_my_very_private_and_secret_test_hook() == 2); # facotry has been used twice

$start = time();
$r1 = $lb1->get();
$r2 = $lb1->get();
$r3 = $lb1->get();
$r4 = $lb1->get();
$r5 = $lb1->get(); 
$r6 = $lb1->get();  # pump up till Max of ResourcePool is reached (5)
ok (defined $r1 && defined $r2 && defined $r3 && defined $r4 && defined $r5 && ! defined $r6);

ok timeinframe(time() - $start, 1);
ok ($f1->_my_very_private_and_secret_test_hook() == 7);

$lb1->free($r1);
$lb1->free($r2);
$lb1->free($r3);
$lb1->free($r4);
$lb1->free($r5);


##################
# two pool tests

my $lb2 = ResourcePool::LoadBalancer->new('lb2', Policy => 'RoundRobin', MaxTry => 3, SleepOnFail => [0]);
my $p2 = ResourcePool->new($f2, Max => 1);
my $p3 = ResourcePool->new($f3, Max => 1);
$lb2->add_pool($p2);
$lb2->add_pool($p3);

$r1 = $lb2->get();
ok (defined $r1 && $r1->{ARGUMENT} eq 'f2');
ok ($f2->_my_very_private_and_secret_test_hook() == 1 && $f3->_my_very_private_and_secret_test_hook() == 0);
$lb2->free($r1);

$r1 = $lb2->get();
ok (defined $r1 && $r1->{ARGUMENT} eq 'f3');
ok ($f2->_my_very_private_and_secret_test_hook() == 1 && $f3->_my_very_private_and_secret_test_hook() == 1);
$lb2->free($r1);

$r1 = $lb2->get();
ok (defined $r1 && $r1->{ARGUMENT} eq 'f2');
ok ($f2->_my_very_private_and_secret_test_hook() == 1 && $f3->_my_very_private_and_secret_test_hook() == 1);
$lb2->free($r1);

$start = time();
$r1 = $lb2->get();
$r2 = $lb2->get();
$r3 = $lb2->get();

ok (defined $r1 && defined $r2 && ! defined $r3);
ok timeinframe(time() - $start, 0);
$lb2->free($r1);
$lb2->free($r2);

my $lb3 = ResourcePool::LoadBalancer->new('lb3', Policy => 'LeastUsage', MaxTry => 3, SleepOnFail => [0]);
$lb3->add_pool($p2, Weight => 50);
$lb3->add_pool($p3, Weight => 150);

my %cnt;
for (my $i = 0; $i < 20; ++$i) {
	$r1 = $lb3->get();
	$lb3->free($r1);
	$cnt{$r1->{ARGUMENT}}++;	
}
ok ($cnt{'f2'} = $cnt{'f3'}*3);

$r1 = $lb3->get();
$r2 = $lb3->get();
$lb3->free($r1);
$lb3->free($r2);
ok(defined $r1 && defined $r2 && $r1->{ARGUMENT} ne $r2->{ARGUMENT});

%cnt= ();
$r1 = $lb3->get();
for (my $i = 0; $i < 20; ++$i) {
	$r2 = $lb3->get();
	$lb3->free($r2);
	$cnt{$r2->{ARGUMENT}}++;	
}
$lb3->free($r1);

ok (($cnt{$r2->{ARGUMENT}} == 20) && (! defined $cnt{$r1->{ARGUMENT}}));

my $lb4 = ResourcePool::LoadBalancer->new('lb4', Policy => 'FallBack', MaxTry => 1, SleepOnFail => [0]);
my $p4 = ResourcePool->new($f4, MaxTry => 1);
$lb4->add_pool($p4, Weight => 50, SuspendTimeout => 1);
$lb4->add_pool($p3, Weight => 150);

%cnt= ();
for (my $i = 0; $i < 20; ++$i) {
	$r2 = $lb4->get();
	$lb4->free($r2);
	$cnt{$r2->{ARGUMENT}}++;	
}

ok ($cnt{'f4'} == 20); # uses normally the first one

$r2->_my_very_private_and_secret_test_hook(0);
$f4->_my_very_private_and_secret_test_hook2(0);

ok (defined ($r1 = $lb4->get()));
$lb4->free($r1);

%cnt= ();
for (my $i = 0; $i < 20; ++$i) {
	$r2 = $lb4->get();
#	print($r2, "\n");
	$lb4->free($r2);
	$cnt{$r2->{ARGUMENT}}++;	
}
ok ($cnt{'f3'} == 20); # second one if first failed

# p4 is supsended for 1 second, so sleep and see if it recoverS
sleep(1);
$f4->_my_very_private_and_secret_test_hook2(1);

$r1 = $lb4->get();
ok ($r1->{ARGUMENT} eq 'f4');

# same again with FailBack

my $lb5 = ResourcePool::LoadBalancer->new('lb5', Policy => 'FailBack', MaxTry => 1, SleepOnFail => [0]);
my $p5 = ResourcePool->new($f5, MaxTry => 1);
$lb5->add_pool($p5, Weight => 50, SuspendTimeout => 1);
$lb5->add_pool($p3, Weight => 150);

%cnt = ();
for (my $i = 0; $i < 20; ++$i) {
	$r2 = $lb5->get();
	$lb5->free($r2);
	$cnt{$r2->{ARGUMENT}}++;	
}

ok ($cnt{'f5'} == 20); # uses normally the first one

$r2->_my_very_private_and_secret_test_hook(0);
$f5->_my_very_private_and_secret_test_hook2(0);

ok (defined ($r1 = $lb5->get()));
$lb5->free($r1);

%cnt= ();
for (my $i = 0; $i < 20; ++$i) {
	$r2 = $lb5->get();
#	print($r2, "\n");
	$lb5->free($r2);
	$cnt{$r2->{ARGUMENT}}++;	
}
ok ($cnt{'f3'} == 20); # second one if first failed

# p4 is supsended for 1 second, so sleep and see if it recoverS
sleep(1);
$f5->_my_very_private_and_secret_test_hook2(1);

$r1 = $lb5->get();
ok ($r1->{ARGUMENT} eq 'f5');


# same again with FailBack

my $lb6 = ResourcePool::LoadBalancer->new('lb6', Policy => 'FailOver', MaxTry => 1, SleepOnFail => [0]);
my $p6 = ResourcePool->new($f6, MaxTry => 1);
$lb6->add_pool($p6, Weight => 50, SuspendTimeout => 1);
$lb6->add_pool($p3, Weight => 150);

%cnt = ();
for (my $i = 0; $i < 20; ++$i) {
	$r2 = $lb6->get();
	$lb6->free($r2);
	$cnt{$r2->{ARGUMENT}}++;	
}

ok ($cnt{'f6'} == 20); # uses normally the first one

$r2->_my_very_private_and_secret_test_hook(0);
$f6->_my_very_private_and_secret_test_hook2(0);

ok (defined ($r1 = $lb6->get()));
$lb6->free($r1);

%cnt= ();
for (my $i = 0; $i < 20; ++$i) {
	$r2 = $lb6->get();
#	print($r2, "\n");
	$lb6->free($r2);
	$cnt{$r2->{ARGUMENT}}++;	
}
ok ($cnt{'f3'} == 20); # second one if first failed

# p4 is supsended for 1 second, so sleep and see if it doesnt recover
sleep(1);
$f6->_my_very_private_and_secret_test_hook2(1);

$r1 = $lb6->get();
ok ($r1->{ARGUMENT} eq 'f3');

# but if we fail again...

$lb6->fail($r1);

$r1 = $lb6->get();
ok ($r1->{ARGUMENT} eq 'f6');



