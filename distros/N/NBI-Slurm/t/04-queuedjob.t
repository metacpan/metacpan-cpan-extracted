use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use_ok 'NBI::QueuedJob';

my $get_jobs = NBI::QueuedJob->new(
    -user => "jose",
    -state => "RUNNING",
    -MIN_CPUS => 1);

isa_ok($get_jobs, 'NBI::QueuedJob');
eval {
    my $bad_job = NBI::QueuedJob->new(
        -user => "jose",
        -state => "RUNNING",
        -MIN_CPUS => 1,
        -bad => 1);
};
ok($@, "Bad attribute");
done_testing();