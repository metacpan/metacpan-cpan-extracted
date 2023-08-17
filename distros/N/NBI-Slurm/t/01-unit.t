use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'NBI::Slurm';

# Can I make a Job instead?
# withouth importing NBI::Job
my $job = NBI::Job->new(-name => "TestJob", -command => "echo 'Hello World'");

done_testing();
