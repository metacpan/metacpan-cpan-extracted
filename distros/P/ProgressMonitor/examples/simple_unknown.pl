# This example script will show almost the simplest possible situation.
#
# We will perform 'some work', but we can't (or don't want to) quantify the
# amount.
#
use strict;
use warnings;

use ProgressMonitor::Stringify::ToStream;
use ProgressMonitor::Stringify::Fields::Spinner;

# Make sure output is unbuffered
#
$| = 1;

# Here we set up a very simple monitor, with one field only - a classic 'spinner'.
# this shows progress, but can not indicate how much remains so it is primarily
# useful for situations where the amount of work is unknown.
#
my $monitor = ProgressMonitor::Stringify::ToStream->new({fields => [ProgressMonitor::Stringify::Fields::Spinner->new,],});

# All monitors must be told to 'prepare'...unless we have no preparatory work to
# do. In that case we can skip the prepare() call and go directly to begin()
# 
# Monitors in the 'prepare' can be 'ticked' if desired; this state is intended
# for the common situation of first finding out the amount to do which typically
# can take a non-negligible amount of time, but little in comparison to the 
# full work.
#
# Here we have no amount to compute, so we just prepare and move on (and we
# could skip the call altogether if we wished).
#
$monitor->prepare();

# After the prepare phase, we must tell the monitor that we are beginning the
# real work.
# If we know the amount we're going to do, we should tell it. Here, we don't know
# so we pass no amount, effectively saying 'unknown'.
# 
$monitor->begin;

# Work for a random time, simulating that we didn't know beforehand how much it was.
#
my $work = rand(10) + 3;
for (1..$work)
{
	# for every piece of isolated work we do, run tick
	# 
	$monitor->tick;
	
	# some time passing
	#
	sleep(1);
}

# finally, we must tell the monitor that we're done, this way it can render
# a last report
#
$monitor->end();
