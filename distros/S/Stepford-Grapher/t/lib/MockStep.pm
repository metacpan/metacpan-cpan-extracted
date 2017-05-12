package MockStep;

use Moose::Role;

with 'Stepford::Role::Step';

# this is just to satisfy the Stepford::Role::Step requirement
# since this will never be run, we don't actually need all this junk
sub last_run_time { undef }
sub run { return }

no Moose::Role;
1;
