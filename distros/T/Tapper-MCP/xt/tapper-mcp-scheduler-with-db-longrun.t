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
use Tapper::Producer::Temare;

use Test::More 0.88;
use Test::Deep;
use Test::MockModule;
use Devel::Backtrace;

                $SIG{INT} = sub {
                        $SIG{INT}='ignore'; # not reentrant, don't handle signal twice
                        my $backtrace = Devel::Backtrace->new(-start=>2, -format => '%I. %s');

                        print $backtrace;

                        exit -1;
                };
BEGIN{
        # --------------------------------------------------------------------------------
        construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_long.yml' );
        # --------------------------------------------------------------------------------
}


use aliased 'Tapper::MCP::Scheduler::Controller';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::WFQ';


model('TestrunDB')->resultset('QueueHost')->new({host_id  => 2, queue_id => 2 })->insert; # addqueue bullock:KVM
model('TestrunDB')->resultset('QueueHost')->new({host_id  => 5, queue_id => 1 })->insert; # addqueue bascha:Xen
# --------------------------------------------------

srand(17); # same random numbers every time

my $algorithm = Algorithm->new_with_traits ( traits => [WFQ] );
my $scheduler = Controller->new (algorithm => $algorithm);

# --------------------------------------------------

my $mock = new Test::MockModule('Tapper::Schema::TestrunDB::Result::TestrunScheduling');
$mock->mock('produce_preconditions',sub{return 0;});

sub toggle_host_free
{
        my @hosts = model("TestrunDB")->resultset("Host")->all;
        my $host = $hosts[int rand(int @hosts)];
        if ($host->free) {
                $host->free(0) if model("TestrunDB")->resultset("Host")->free_hosts->count > 1;
        } else {
                $host->free(1);
        }
        $host->update();
}

my $next_job;
my @jobqueue;
my %jobs;
# Job 1

eval{
        for (my $i=0; $i<180; $i++) {

                $next_job   = $scheduler->get_next_job();
                if ($next_job) {
                        print STDERR ".";
                        push @jobqueue, $next_job->queue->name;
                        $jobs{$next_job->queue->name}++;
                        $scheduler->mark_job_as_running($next_job);
                } else {
                        print STDERR ",";
                        $jobs{none}++;
                }

                toggle_host_free();

        }
};
print $@ if $@;

print STDERR "\n# ".Dumper \%jobs;
print STDERR "# ".join(", ", @jobqueue);

is($jobs{Kernel}, 24,'Kernel queue bandwith');
is($jobs{KVM}, 49,'KVM queue bandwith');
is($jobs{Xen}, 74, 'Xen queue bandwith');
is($jobs{none}, 33, 'Always jobs');

ok(1, 'Dummy');

done_testing();

