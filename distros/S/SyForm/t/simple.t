#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SyForm;

my $form = SyForm->new(
  fields => [
    'test' => {},
  ]
);

ok($form->isa('SyForm'),'$form isa SyForm');
my $n = 0;
for my $name ($form->fields->Keys) {
  $n++;
  my $field = $form->field($name);
  ok($field->does('SyForm::FieldRole::Process'),'process role loaded on field');
}
is($n,1,'one field');
my $emptyview = $form->process();
ok($emptyview->isa('SyForm::View'),'$emptyview isa SyForm::View');
my $emptyresult = $emptyview->results();
ok($emptyresult->isa('SyForm::Results'),'Result is SyForm::Results');
ok(!$emptyresult->has_result('test'),'Result has no value for test');
is_deeply($emptyresult->as_hashref,{},'Result hash is empty');
my $result = $form->process_results( test => 12, ignored => 2 );
ok($result->isa('SyForm::Results'),'Result is SyForm::Results');
is($result->get_result('test'),12,'Result of test is fine');
is_deeply($result->as_hashref,{ test => 12 },'Result as hash is fine');

my $form2 = SyForm->new(
  fields => [
    'test' => {},
    'test2' => {
      label => 'Test Label',
    },
    'test3' => {
      label => 'Test Label',
    },
    'test4' => {
    },
  ]
);

my $test_field = $form2->field('test');
ok($test_field->does('SyForm::FieldRole::Process'),'process role loaded on 1st field');
my $form2view = $form2->process( test2 => 'lalala' );
ok($form2view->isa('SyForm::View'),'$form2view isa SyForm::View');
my $result2 = $form2view->results();
ok($result2->has_result('test2'),'Has a test2 result value');
is($result2->get_result('test2'),'lalala','Expected test2 result value');
ok(!$result2->has_result('test'),'Has no test result value');
ok($result2->isa('SyForm::Results'),'Result isa SyForm::Results');
is_deeply($result2->field_names,[qw(
  test test2 test3 test4
)],'Field names are in correct order');

my $result3 = SyForm->new(
  fields => [
    'test' => {},
    'test2' => {
      label => 'Test Label',
    },
    'test3' => {},
    'test4' => {},
    'test5' => {},
  ]
)->process_results();

is_deeply($result3->field_names,[qw(
  test test2 test3 test4 test5
)],'Other field names are also in correct order');

done_testing;