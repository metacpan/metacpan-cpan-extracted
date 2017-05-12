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
BEGIN{
        # --------------------------------------------------------------------------------
        construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_features.yml' );
        # --------------------------------------------------------------------------------
}
use aliased 'Tapper::MCP::Scheduler::Controller';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm';
use Test::More;
use Test::Deep;


# --------------------------------------------------

my $algorithm = Algorithm->new_with_traits ( traits => [DummyAlgorithm] );
my $scheduler = Controller->new (algorithm => $algorithm);

# --------------------------------------------------


my $next_job = $scheduler->get_next_job();
is($next_job->host->name, "kobold", "fitting host kobold");
$scheduler->mark_job_as_running($next_job);
my $job1=$next_job;

$next_job = $scheduler->get_next_job();
is($next_job, undef, "no job since no other machine with ecc");


$scheduler->mark_job_as_finished($job1);


done_testing();
