#!perl

use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;


use Test::More;
use Tapper::Cmd::Requested;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $requested = Tapper::Cmd::Requested->new();
isa_ok($requested, 'Tapper::Cmd::Requested', 'Object');


my $id = $requested->add_host(3001, 'iring');
my $host = model('TestrunDB')->resultset('Testrun')->find(3001)->testrun_scheduling->requested_hosts->first->host->name;
is($host, 'iring',  'Add requested host');

$id = $requested->add_feature(3001, 'mem > 4096');
my $feature = model('TestrunDB')->resultset('Testrun')->find(3001)->testrun_scheduling->requested_features->first->feature;
is($feature, 'mem > 4096',  'Add requested feature');

done_testing();
