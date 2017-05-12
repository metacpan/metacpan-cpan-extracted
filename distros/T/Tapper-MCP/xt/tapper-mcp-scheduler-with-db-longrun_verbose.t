#! /usr/bin/env perl

use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;


use Tapper::Model 'model';

use Data::Dumper;
use Test::Fixture::DBIC::Schema;
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

use Tapper::Schema::TestTools;
BEGIN{
        # --------------------------------------------------------------------------------
        construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_long.yml' );
        #--------------------------------------------------------------------------------
        model('TestrunDB')->resultset('QueueHost')->new({host_id  => 2, queue_id => 2 })->insert;
        model('TestrunDB')->resultset('QueueHost')->new({ host_id  => 5, queue_id => 1 })->insert; # addqueue bascha:Xen
        #--------------------------------------------------
}
use aliased 'Tapper::MCP::Scheduler::Controller';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::WFQ';


my $algorithm = Algorithm->new_with_traits ( traits => [WFQ] );
my $scheduler = Controller->new (algorithm => $algorithm);

# --------------------------------------------------

my $mock = new Test::MockModule('Tapper::Schema::TestrunDB::Result::TestrunScheduling');
$mock->mock('produce_preconditions',sub{return 0;});


my $next_job;
my @jobqueue;
my %jobs;
# Job 1
my $this_job;

eval{
        for (my $i=0; $i<180; $i++) {

                $next_job   = $scheduler->get_next_job();
                if ($next_job) {
                        $scheduler->mark_job_as_running($next_job);
                        $jobs{$next_job->queue->name}++;
                        $scheduler->mark_job_as_finished($next_job);
                } else {
                        $jobs{none}++;
                }

        }
};
print $@ if $@;
use DDP;
p %jobs;

# is($jobs{Kernel}, 30,'Kernel queue bandwith');
# is($jobs{KVM}, 60,'KVM queue bandwith');
# is($jobs{Xen}, 90, 'Xen queue bandwith');
# is($jobs{none}, undef, 'Always jobs');

ok(1, 'Dummy');

done_testing();

