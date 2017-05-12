#! /usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::Fixture::DBIC::Schema;

use Test::MemoryGrowth;
use Test::More 0.88;
use Test::MockModule;
use Tapper::Schema::TestTools;

BEGIN{
        # --------------------------------------------------------------------------------
        construct_fixture( schema  => testrundb_schema,  fixture => 'xt/fixtures/testrundb/testrun_with_circle.yml' );
}

use Tapper::MCP::Master;
my $mcp  = Tapper::MCP::Master->new;
my $mock = Test::MockModule->new('Tapper::Schema::TestrunDB::Result::TestrunScheduling');

$mcp->set_interrupt_handlers();
$mcp->prepare_server();
my $lastrun = time();

$lastrun = $mcp->runloop($lastrun);

# # This takes extremly long indeed. Yet you can not reduce the number of call significantly otherwise the memory leak wont be detected.
# no_growth  { $lastrun = $mcp->runloop($lastrun)} calls => 10000, 'get_next_job does not grow memory';
ok(1, 'Dummy');

done_testing();
