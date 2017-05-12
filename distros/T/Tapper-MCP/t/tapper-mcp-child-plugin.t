#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
#use Tapper::Schema::TestTools;
use Tapper::Model 'model';

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_local.yml' );
# -----------------------------------------------------------------------------------------------------------------



use_ok('Tapper::MCP::Child');
my $tr = model('TestrunDB')->resultset('Testrun')->first;
my $child = Tapper::MCP::Child->new({testrun => $tr, plugin_conf => {Test => 'All'}});
isa_ok($child, 'Tapper::MCP::Child');
my $res = $child->console_start();
is($res, 'test', 'Console start with test plugin');
