#! /usr/bin/env perl

use strict;
use warnings;

#
# Test whether auto_rerun works as expected
#


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
        construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_run2.yml' );
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
my @precondition_ids;


# Job 1
$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron iring bullock dickstone athene bascha)], "free hosts");

$next_job   = $scheduler->get_next_job();
is($next_job->id, 301, "next fitting host");
is($next_job->host->name, "iring", "fitting host iring");
is($next_job->testrun->shortname, "ccc-kernel", "Shortname testrun");
$scheduler->mark_job_as_running($next_job);

$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron bullock dickstone athene bascha)], "free hosts: iring taken ");


my @all_preconditions = $next_job->testrun->ordered_preconditions;
is($all_preconditions[3]->precondition_as_hash->{precondition_type}, 'produce', 'Producer not evaluated');
is($next_job->testrun->topic_name, 'old_topic', 'Topic unchanged');

$scheduler->mark_job_as_finished($next_job);




# Job 2
$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron iring bullock dickstone athene bascha)], "free hosts");

$next_job   = $scheduler->get_next_job();
is($next_job->id, 302, "next fitting host");
is($next_job->host->name, "iring", "fitting host iring");
is($next_job->testrun->shortname, "ccc2-kernel", "Shortname testrun");
$scheduler->mark_job_as_running($next_job);

$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron bullock dickstone athene bascha)], "free hosts: iring taken ");

my $preconditions = $next_job->testrun->ordered_preconditions;
@all_preconditions = map {$_->precondition} $next_job->testrun->ordered_preconditions;
$scheduler->mark_job_as_finished($next_job);




# Job 3
$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron iring bullock dickstone athene bascha)], "free hosts");

$next_job   = $scheduler->get_next_job();
is($next_job->testrun->shortname, "ccc-kernel", "Shortname testrun");
is($next_job->host->name, "iring", "fitting host iring");
$scheduler->mark_job_as_running($next_job);

$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron bullock dickstone athene bascha)], "free hosts: iring taken ");

$scheduler->mark_job_as_finished($next_job);





# Job 4
$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron iring bullock dickstone athene bascha)], "free hosts");

$next_job   = $scheduler->get_next_job();
is($next_job->testrun->shortname, "ccc-kernel", "Shortname testrun");
is($next_job->host->name, "iring", "fitting host iring");
$scheduler->mark_job_as_running($next_job);

$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron bullock dickstone athene bascha)], "free hosts: iring taken ");

$scheduler->mark_job_as_finished($next_job);



# Job 5
$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron iring bullock dickstone athene bascha)], "free hosts");

$next_job   = $scheduler->get_next_job();
is($next_job->testrun->shortname, "ccc-kernel", "Shortname testrun");
is($next_job->host->name, "iring", "fitting host iring");
$scheduler->mark_job_as_running($next_job);

$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
@free_host_names = map { $_->name } $free_hosts->all;
cmp_bag(\@free_host_names, [qw(yaron bullock dickstone athene bascha)], "free hosts: iring taken ");

$scheduler->mark_job_as_finished($next_job);



# prepare db changes
my $host = model("TestrunDB")->resultset("Host")->find(10); # host yaron
my $queuehost = $host->queuehosts->first;
$queuehost->queue_id(3);  # kernel queue
$queuehost->update;

# 310 is bound-kernel, a testrun that requests host yaron
my $job = model("TestrunDB")->resultset("TestrunScheduling")->find(310);
$job->status('schedule');
$job->update;

# clean merged queue
$next_job = $scheduler->get_next_job();
$scheduler->mark_job_as_running($next_job);
$scheduler->mark_job_as_finished($next_job);
$next_job = $scheduler->get_next_job();
$scheduler->mark_job_as_running($next_job);
$scheduler->mark_job_as_finished($next_job);


$next_job = $scheduler->get_next_job();
is($next_job->testrun->shortname, "bound-kernel", "Shortname testrun is bound-kernel");
is($next_job->host->name, "yaron", "fitting host yaron");
$scheduler->mark_job_as_running($next_job);
$scheduler->mark_job_as_finished($next_job);


# Queue bound tests
$free_hosts = model("TestrunDB")->resultset("Host")->free_hosts;
while (my $free_host = $free_hosts->next) {
        $free_host->free(0);
        $free_host->update;
}

$host = model("TestrunDB")->resultset("Host")->find(10);
$host->free(1);
$host->update();

$queuehost = $host->queuehosts->first;
$queuehost->queue_id(2);  # KVM queue
$queuehost->update;

$next_job   = $scheduler->get_next_job();
is($next_job, undef, 'No job when only available host is bound to empty queue');



$queuehost->queue_id(3);  # kernel queue
$queuehost->update;

# do not pick ccc-kernel since it's requested host ist correctly set to iring and only yaron is free
$next_job = $scheduler->get_next_job();
is($next_job->testrun->shortname, "bound-kernel", "Shortname testrun");
is($next_job->host->name, "yaron", "fitting host yaron");
$scheduler->mark_job_as_running($next_job);
$scheduler->mark_job_as_finished($next_job);



done_testing;

