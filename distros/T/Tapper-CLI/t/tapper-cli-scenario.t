#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $scenario_id = `$^X -Ilib bin/tapper scenario-new --file t/files/interdep.sc`;
chomp $scenario_id;
ok($scenario_id, 'newscenario returns a true value');
my $scenario = model('TestrunDB')->resultset('Scenario')->find($scenario_id);
ok($scenario, 'Find new scenario in DB');

is($scenario->scenario_elements->count, 2, 'Number of testruns in scenario');

diag( `$^X -Ilib bin/tapper scenario-new --file t/files/interdep.sc` );

foreach my $element ( $scenario->scenario_elements->all ) {
        my @hosts = map {$_->host->name} $element->testrun->testrun_scheduling->requested_hosts;
        cmp_bag(\@hosts, ['bullock','dickstone'], 'Requested hosts for testrun');  # both testruns request the same hosts
        my $precond_type = $element->testrun->testrun_precondition->first->precondition->precondition_as_hash->{precondition_type};
        is($precond_type, 'image', 'first precondition\'s type');
}


done_testing();
