#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SyForm;

my $form = SyForm->new(
  fields => [
    'require' => {
      required => 1,
    },
    'integer' => {
      verify => [ is_number => 1 ],
    },
    'reqint' => {
      required => 1,
    },
  ]
);

ok($form->isa('SyForm'),'$form isa SyForm');
my $view = $form->process( require => 'something', reqint => 2 );
my $results = $view->results;
ok($view ? 1 : 0,'$view is bool success');
ok($results ? 1 : 0,'$results is bool success');
ok($results->isa('SyForm::Results'),'$results isa SyForm::Results');
ok($results->does('SyForm::ResultsRole::Success'),'$results does SyForm::ResultsRole::Success');
ok($results->does('SyForm::ResultsRole::Verify'),'$results does SyForm::ResultsRole::Verify');
ok($results->success,'$results is a success');
is($results->get_result('require'),'something','result is field with value');
ok(!$results->has_result('integer'),'integer field has no result');
is($results->get_result('reqint'),'2','result is field with value');
my $emptyview = $form->process();
my $emptyresults = $emptyview->results;
ok($emptyview ? 0 : 1,'$emptyview is no bool success');
ok($emptyresults ? 0 : 1,'$emptyresults is no bool success');
ok(!$emptyresults->has_result('require'),'require field has no result');
ok(!$emptyresults->has_result('integer'),'integer field has no result');
ok(!$emptyresults->has_result('reqint'),'reqint field has no result');
my $badresults = $form->process_results(
  require => 'something',
  integer => "text",
  reqint => 2,
);
is($badresults->error_count,1,'$badresults error_count is 1');
ok(!$badresults->success,'$badresults is no success');
is($badresults->get_result('require'),'something','result is field with value');
ok(!$badresults->has_result('integer'),'integer field has no result');
is($badresults->get_result('reqint'),'2','reqint has valid value');

done_testing;