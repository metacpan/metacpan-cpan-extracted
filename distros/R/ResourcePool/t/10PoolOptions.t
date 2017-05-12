#! /usr/bin/perl -w
#*********************************************************************
#*** t/10PoolOptions.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 10PoolOptions.t,v 1.5 2009-11-25 11:00:10 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Factory;

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

BEGIN { plan tests => 25; };

# there shall be silence
$SIG{'__WARN__'} = sub {};


my $f1 = ResourcePool::Factory->new('f1');
my $f2 = ResourcePool::Factory->new('f2');
my $f3 = ResourcePool::Factory->new('f3');
my $f4 = ResourcePool::Factory->new('f4');
my $f5 = ResourcePool::Factory->new('f5');
ok ((defined $f1) && (defined $f2) && (defined $f3) && (defined $f4) && (defined $f5));

my $p1 = ResourcePool->new($f1, PreCreate => 3);
my $p2 = ResourcePool->new($f2, Max => 1, SleepOnFail => [1]);
my $p3 = ResourcePool->new($f3, {Max => 1, PreCreate => 1});
my $p4 = ResourcePool->new($f4, {Max => 1, MaxTry => 4, SleepOnFail => [0,1,2]});
my $p5 = ResourcePool->new($f5, {Max => 1, MaxTry => 3, SleepOnFail => [0,1,2], PreCreate => 10});
ok ((defined $p1) && (defined $p2) && (defined $p3) && (defined $p4) && (defined $p5));

{
# test Max Option/default
ok ($f1->_my_very_private_and_secret_test_hook() == 3);
my $start = time();
my $r1 = $p1->get();
my $r2 = $p1->get();
my $r3 = $p1->get();
my $r4 = $p1->get();
my $r5 = $p1->get();
ok ((defined $r1) && (defined $r2) && (defined $r3) && (defined $r4) && (defined $r5));
ok ($f1->_my_very_private_and_secret_test_hook() == 5);

my $r6 = $p1->get();
my $stop = time();
ok(!(defined $r6));
ok timeinframe (($stop - $start) , 0);
}

{
# test Max Option 1
ok ($f2->_my_very_private_and_secret_test_hook() == 0);
my $r1 = $p2->get();
ok ((defined $r1));
ok ($f2->_my_very_private_and_secret_test_hook() == 1);

my $start = time();
my $r2 = $p2->get();
my $stop = time();
ok(!(defined $r2));

ok timeinframe (($stop - $start) , 1);
ok ($f2->_my_very_private_and_secret_test_hook() == 1);
}

{
# test Max Option 1
ok ($f3->_my_very_private_and_secret_test_hook() == 1);
my $start = time();
my $r1 = $p3->get();
ok ((defined $r1));

my $r2 = $p3->get();
ok(!(defined $r2));

$p3->free($r1);
$r2 = $p3->get();
my $stop = time();
ok((defined $r2));
ok timeinframe(($stop - $start) , 0);
}

{
# test Max Option 1
my $start = time();
my $r1 = $p4->get();
ok ((defined $r1));

my $r2 = $p4->get();
ok(!(defined $r2));
my $stop = time();

ok timeinframe(($stop - $start) , 3);
}

{
# test Max Option 1
ok ($f5->_my_very_private_and_secret_test_hook() == 1);
my $start = time();
my $r1 = $p5->get();
ok ((defined $r1));

my $r2 = $p5->get();
ok(!(defined $r2));
my $stop = time();

ok timeinframe($stop - $start, 1);
}

