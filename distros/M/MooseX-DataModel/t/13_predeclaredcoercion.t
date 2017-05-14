#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use Moose::Util::TypeConstraints;

subtype 'PrependST',
     as 'Str';

coerce 'PrependST',
  from 'Str',
   via { "ST: $_" };

package TestModel {
  use MooseX::DataModel;
  key att1 => (isa => 'PrependST', coerce => 1);
  array att2 => (isa => 'PrependST');
  object att3 => (isa => 'PrependST');
}

{
  my $ds = { att1 => 'val1', att2 => [ 'val2' ], att3 => { 'att3key1' => 'att3val1' } };
  my $model = TestModel->new($ds);

  TODO: {
    $TODO = 'Not implemented yet';
    cmp_ok($model->att1, 'eq', 'ST: val1');
    cmp_ok($model->att2->[0], 'eq', 'ST: val2');
    cmp_ok($model->att3->{ att3key1 }, 'eq', 'ST: att3val1');
  };
}

done_testing;
