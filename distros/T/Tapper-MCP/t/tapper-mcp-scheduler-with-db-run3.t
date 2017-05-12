#! /usr/bin/env perl

use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;


use Tapper::Model 'model';

use Data::Dumper;
use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;

use Test::More;
use Test::Deep;
BEGIN{
        # --------------------------------------------------------------------------------
        construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_run1.yml' );
        # --------------------------------------------------------------------------------
}
use aliased 'Tapper::MCP::Scheduler::Controller';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm';


# --------------------------------------------------

my $algorithm = Algorithm->new_with_traits ( traits => [DummyAlgorithm] );
my $scheduler = Controller->new (algorithm => $algorithm);

# --------------------------------------------------

my $free_hosts;
my $next_job;
my @free_host_names;

# Queue bound tests
$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
while (my $host = $free_hosts->next) {
        $host->free(0);
        $host->update;
}
$next_job = $scheduler->get_next_job();
is($next_job, undef, "No fitting since no free machines");


# Queue bound tests
my $all_hosts = model("TestrunDB")->resultset("Host");
while (my $host = $all_hosts->next) {
        $host->free(1);
        $host->update;
}

####################################################################################
#                                                                                  #
# prepare testruns. Each testrun requests a host with feature 'more than 5GB RAM'. #
# Delete all requested hosts to make sure they don't interfere with this test.     #
#                                                                                  #
####################################################################################
my $requested_host_rs = model('TestrunDB')->resultset('TestrunRequestedHost');
foreach my $requested_host($requested_host_rs->all) {
        $requested_host->delete();
}
my $testrun_rs = model('TestrunDB')->resultset('Testrun');
while (my $tr = $testrun_rs->next()) {
        my $feature=model('TestrunDB')->resultset('TestrunRequestedFeature')->new({testrun_id => $tr->id, feature => 'mem > 5000'});
        $feature->insert;
}

$next_job = $scheduler->get_next_job();
is($next_job->host->name, "iring", "fitting host iring");
$scheduler->mark_job_as_running($next_job);
my $job1=$next_job;

{
        local $^W;
$next_job = $scheduler->get_next_job();
}
is($next_job, undef, "no job since only host with more than 5GB RAM is in use");


$scheduler->mark_job_as_finished($job1);


done_testing();
