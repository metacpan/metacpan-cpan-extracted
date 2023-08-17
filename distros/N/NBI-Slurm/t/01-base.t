use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'NBI::Slurm';
use_ok 'NBI::Job';
use_ok 'NBI::Opts';
use_ok 'NBI::QueuedJob';
use_ok 'NBI::Queue';

done_testing();