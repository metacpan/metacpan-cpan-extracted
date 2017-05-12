#!perl

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use warnings;
use strict;

use Test::More;

use Tapper::Cmd::Testplan;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------

my $cmd = Tapper::Cmd::Testplan->new();
isa_ok($cmd, 'Tapper::Cmd::Testplan', '$testrun');


#######################################################
#
#   check add method
#
#######################################################
open my $fh, '<', 't/misc_files/testplan.mpc' or die "Can not open 't/misc_files/testplan.mpc': $!";
my $content; {local $/; $content = <$fh>};
close $fh;

my $testplan_id = $cmd->add($content, 'test.for.testplan.support');
ok(defined($testplan_id), 'Adding testrun');

my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($testplan_id);
is($testplan->testruns->count, 4, 'Testruns for testplan created');

my $rerun_id = $cmd->rerun($testplan_id);
ok(defined($rerun_id), 'Rerun testplan');


my $rerun_testplan = model('TestrunDB')->resultset('TestplanInstance')->find($rerun_id);

is($rerun_testplan->testruns->count, $testplan->testruns->count, 'Rerun/ Number of testruns');
is($rerun_testplan->name, $testplan->name, 'Rerun/ Name of testplan');
is($rerun_testplan->path, $testplan->path, 'Rerun/ Path of testplan');
isnt($rerun_testplan->id, $testplan->id, 'Rerun/ Path of testplan');

#######################################################
#
#   check update method
#
#######################################################



#######################################################
#
#   check del method
#
#######################################################

my $retval = $cmd->del($testplan_id);
is($retval, 0, 'Delete testplan instance');
$testplan = model('TestrunDB')->resultset('Testrun')->find($testplan_id);
is($testplan, undef, 'Testplan instance is gone');

#######################################################
#
#   check testplans with scenarios
#
#######################################################

open $fh, '<', 't/misc_files/testplan_with_scenario.mpc' or die "Can not open 't/misc_files/testplan_with_scenario.mpc': $!";
$content = do {local $/; <$fh>};

$testplan_id = $cmd->add($content, 'test.for.testplan.support');
ok(defined($testplan_id), 'Adding testrun');

$testplan = model('TestrunDB')->resultset('TestplanInstance')->find($testplan_id);
is($testplan->testruns->count, 3, 'Testruns for testplan created');
my @scenario_ids = map {$_->scenario_element->scenario->id} grep { defined $_->scenario_element } $testplan->testruns->all;
is_deeply(\@scenario_ids, [1, 1], 'Scenario in testplan');

#######################################################
#
#   check testplannew
#
#######################################################


$testplan_id = $cmd->testplannew({file => 't/misc_files/testplan_with_substitutes.tp',
                                  name => 'Zomtec',
                                  path => 'la.le.lu',
                                  include => ['t/includes/'],
                                  substitutes => {hosts_all => ['bullock', 'dickstone'],
                                                  hosts_any => ['iring', 'bascha'], },
                            });
$testplan = model('TestrunDB')->resultset('TestplanInstance')->find($testplan_id);
is($testplan->testruns->count, 4, 'Testruns for testplan created');

done_testing;
