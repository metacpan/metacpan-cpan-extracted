#!/usr/bin/env perl

use strict;
use warnings;

use Tapper::Model 'model';
use Tapper::Schema::TestTools;

use Test::More;
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/scenario_testruns.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $tr = model('TestrunDB')->resultset('Testrun')->find(1001);
ok($tr->scenario_element, 'Testrun 1001 is part of a scenario');
is($tr->scenario_element->peer_elements->count, 2, 'Number of test runs in scenario');
is($tr->scenario_element->peers_need_fitting, 2, 'Number of unfitted test runs in scenario');

$tr->scenario_element->is_fitted(1);
$tr->scenario_element->update;

is($tr->scenario_element->peers_need_fitting, 1, 'Number of unfitted test runs in scenario after fitting $self');

done_testing();
