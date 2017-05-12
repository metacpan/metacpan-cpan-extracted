#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;
use File::Temp 'tempdir';
use Log::Log4perl;
use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;
use YAML;
BEGIN{
        # -----------------------------------------------------------------------------------------------------------------
        construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/scenario_testruns.yml' );
        # -----------------------------------------------------------------------------------------------------------------
}

use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm';
use aliased 'Tapper::MCP::Scheduler::Controller';

use Tapper::Model 'model';
use Tapper::Config;
use Tapper::MCP::Config;

use Test::More;

my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);




# Scheduling order: (KVM, Kernel, Xen)*

my $algorithm = Algorithm->new_with_traits ( traits => [DummyAlgorithm] );
my $scheduler = Controller->new (algorithm => $algorithm);


my $tr = model('TestrunDB')->resultset('Testrun')->find(1001);
ok($tr->scenario_element, 'Testrun 1001 is part of a scenario');
is($tr->scenario_element->peer_elements->count, 2, 'Number of test runs in scenario');

my @next_jobs   = $scheduler->get_next_job();
is($next_jobs[0]->queue->name, 'KVM', 'Job is KVM job');

@next_jobs   = $scheduler->get_next_job();
is($next_jobs[0]->queue->name, 'Kernel', 'Job is Kernel job');

@next_jobs   = $scheduler->get_next_job();
is(scalar @next_jobs, 0, 'Hold Xen job back until scenario is fully fitted');

@next_jobs   = $scheduler->get_next_job();
my @job_ids  = map {$_->id} @next_jobs;
is(scalar @next_jobs, 2, 'Priorise scenario elements when one scenario element is already matched');
is_deeply(\@job_ids, [101, 102], 'Return all jobs when scenario is fully fitted');



is($next_jobs[0]->testrun->scenario_element->peer_elements, 2, 'Number of peers including $self');
my $dir = tempdir( CLEANUP => 1 );
my $config = Tapper::Config->subconfig;

$config->{paths}{sync_path} = $dir;
my $testrun = $next_jobs[0]->testrun;
$config->{testrun} = $testrun->id;


my $mcp_conf = Tapper::MCP::Config->new($next_jobs[0]->testrun->id);
$config      = $mcp_conf->get_common_config();
if (ref($config) eq 'HASH') {
        pass('Returned config is a hash ref');
} else {
        fail("Get_common_config returned error string $config");
}

my $syncfile = "$config->{paths}{sync_path}/syncfile";
ok(-e $syncfile, "Syncfile $syncfile exists");
eval
{
        my $peers = YAML::LoadFile($syncfile);
        is(ref $peers, 'ARRAY', 'Array of hosts in sync file');
};
fail('No valid YAML in syncfile: $@') if $@;

@next_jobs   = $scheduler->get_next_job();
is($next_jobs[0]->queue->name, 'KVM', 'Job is KVM job');

@next_jobs   = $scheduler->get_next_job();
is($next_jobs[0]->queue->name, 'Kernel', 'Job is Kernel job');


done_testing();
