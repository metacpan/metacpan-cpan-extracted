#! /usr/bin/env perl

use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;

use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;

use aliased 'Tapper::MCP::Scheduler::Controller';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm';

use Tapper::Model 'model';

use Data::Dumper;

use Test::More;
use Test::Deep;

# --------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_run4.yml' );
# --------------------------------------------------------------------------------

# --------------------------------------------------

my $algorithm = Algorithm->new_with_traits ( traits => [DummyAlgorithm] );
my $scheduler = Controller->new (algorithm => $algorithm);

# --------------------------------------------------

my $free_hosts;
my $next_job;
my @free_host_names;

my $testrun_rs = model('TestrunDB')->resultset('Testrun');
while (my $tr = $testrun_rs->next()) {
        my $feature=model('TestrunDB')->resultset('TestrunRequestedFeature')->new({testrun_id => $tr->id, feature => 'hostname ne bullock'});
        $feature->insert;
};

$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(iring bullock)], "free hosts");

{
        local $^W;
        $next_job = $scheduler->get_next_job();
}
is($next_job->host->name, "iring", "fitting host iring");
$scheduler->mark_job_as_running($next_job);
my $job1=$next_job;

{
        local $^W;
        $next_job = $scheduler->get_next_job();
}
is($next_job, undef, "no job since only bullock free");


$scheduler->mark_job_as_finished($job1);


done_testing();
