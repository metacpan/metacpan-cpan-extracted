use strict;
use warnings;

use Tapper::Schema::TestTools;
use Tapper::Model 'model';

use Test::Fixture::DBIC::Schema;
use Test::WWW::Mechanize::Catalyst;


use Test::More;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns.yml' );
# -----------------------------------------------------------------------------------------------------------------


BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper::Testruns' }

my @precond_ids_before = map{$_->id} model('TestrunDB')->resultset('Testrun')->find(1)->ordered_preconditions;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Tapper::Reports::Web');
$mech->get_ok('/tapper/testruns/id/1');
$mech->follow_link_ok({text => 'Edit precondition'}, "Click on 'Edit precondition'");
my $form = $mech->forms(0);
is(scalar($mech->find_all_inputs(name => 'preconditions')), 1, 'Form with input for update preconditions');

$mech->forms(0);
$mech->submit_form(button => 'submit');

my @precond_ids_after = map{$_->id} model('TestrunDB')->resultset('Testrun')->find(1)->ordered_preconditions;
isnt(join(",",@precond_ids_before), join(",",@precond_ids_after), 'New preconditions attached');
is(scalar @precond_ids_after, 2, 'Two preconditions attached');

my @testprogram = grep{$_->precondition_as_hash->{precondition_type} eq 'testprogram'} model('TestrunDB')->resultset('Testrun')->find(1)->ordered_preconditions;
isnt($testprogram[0]->timeout, undef, 'Timeout for testprogram');

done_testing;
