package ProgressMonitor::State;

use strict;
use warnings;

# This defines the values used to track state for monitors - used by
# AbstractStatefulMonitor
#

use Exporter qw(import);
our @EXPORT = qw(STATE_NEW STATE_PREPARING STATE_ACTIVE STATE_DONE);

# This state is when the monitor is just created
#
sub STATE_NEW ()       { 0 }

# The monitor has been told that the task is preparing
#
sub STATE_PREPARING () { 1 }

# The task has now begun its main work
#
sub STATE_ACTIVE ()    { 2 }

# The task is done
#
sub STATE_DONE ()      { 3 }

1;
