# This example script will show almost the simplest possible situation.
#
# We will perform 'some work', and we will quantify the amount to be done
# so the monitor can give the user feedback on where we are and allow an 
# estimate when it might be ready.
#
use strict;
use warnings;

use ProgressMonitor::Stringify::ToStream;
use ProgressMonitor::Stringify::Fields::Counter;

# Make sure output is unbuffered
#
$| = 1;

# Compute a simulated time we have to work
#
my $work = rand(10) + 3;

# Here we set up a very simple monitor, with one field only - a 'counter'.
# This shows counted progress, as well as indicates how much remains so it is
# well suited to work when we know how long it will take.
#
my $monitor = ProgressMonitor::Stringify::ToStream->new({fields => [ProgressMonitor::Stringify::Fields::Counter->new,],});

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
# Since we know the amount we're going to do, we tell it.
# 
$monitor->begin($work);

# now, get to work!
#
for (1..$work)
{
	# For every piece of isolated work we do, run tick with the amount
	# we've done. Note that we should not tick more than what we said that 
	# we should do, but it's permissible to do less (for example because
	# the work ended prematurely due to some problem).
	# 
	$monitor->tick(1);
	
	# some time passing
	#
	sleep(1);
}

# Finally, we must tell the monitor that we're done, this way it can render
# a last report.
# Note that we must do this even if we ended prematurely.
#
$monitor->end();
