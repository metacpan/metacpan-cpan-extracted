#!perl

use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use Test::More;

use Tapper::Cmd::Scenario;
use Tapper::Model 'model';
use YAML::XS;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $scen = Tapper::Cmd::Scenario->new();
isa_ok($scen, 'Tapper::Cmd::Scenario', '$scenario');

my $scenario = do {local $/;
                   open (my $fh, '<', 't/misc_files/scenario.sc') or die "Can open file:$!\n";
                   <$fh>
           };

my @retval  = $scen->add([YAML::XS::Load($scenario)]);
my $scen_rs = model('TestrunDB')->resultset('Scenario')->find($retval[0]);
isa_ok($scen_rs, 'Tapper::Schema::TestrunDB::Result::Scenario', 'Insert scenario / scenario id returned');

my $retval  = $scen->del($scen_rs->id);
is($retval, 0, 'Delete scenario');
$scen_rs = model('TestrunDB')->resultset('Scenario')->find($scen_rs->id);

$scenario = do {local $/;
                   open (my $fh, '<', 't/misc_files/single.sc') or die "Can open file 'single.sc':$!\n";
                   <$fh>
           };

@retval  = $scen->add([YAML::XS::Load($scenario)]);
foreach my $id (@retval) {
        my $scenario_res = model('TestrunDB')->resultset('Scenario')->find($id);
        isa_ok($scenario_res, 'Tapper::Schema::TestrunDB::Result::Scenario', 'Insert single scenario / testrun id returned');
        my @testrun_ids = map {$_->testrun->id} $scenario_res->scenario_elements->all;
        isnt(int @testrun_ids, 0, 'Testruns associated to scenario');
}

done_testing();

