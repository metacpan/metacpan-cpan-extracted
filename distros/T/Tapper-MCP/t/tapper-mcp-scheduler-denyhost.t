#! /usr/bin/env perl

# =========================================================
#
# Test "queue denies host" handling in MCP scheduler
#
# =========================================================

use strict;
use warnings;

# get rid of warnings
use Class::C3;
use MRO::Compat;

use Tapper::Model 'model';

use Data::Dumper;
use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;

use Test::More tests => 1;
use Test::Deep;
BEGIN {
        # --------------------------------------------------------------------------------
        construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_deny.yml' );
        # --------------------------------------------------------------------------------
}


use aliased 'Tapper::MCP::Scheduler::Controller';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::WFQ';
use aliased 'Tapper::Producer::DummyProducer';

# --------------------------------------------------

my $algorithm = Algorithm->new_with_traits ( traits => [WFQ] );
my $scheduler = Controller->new (algorithm => $algorithm);

# --------------------------------------------------

my $free_hosts;
my $next_job;
$next_job = $scheduler->get_next_job();

# This test not only checks whether a queue correctly obeys the "deny this host" request
# It also checks whether the list of free hosts is unaffected for other queues. This is an
# important part that I like to have in the test too.
is($next_job->id, 201, 'Xen queue has highest prio but KVM job choosen because the only free hosts is denied by Xen queue');
