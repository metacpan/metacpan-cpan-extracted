#!/usr/bin/env perl

use Test::More;
use Test::Exception;

package TestModel {
  use MooseX::DataModel;
  key bool => (isa =>  'Bool');
  array arr => (isa => 'Bool');
  object obj => (isa => 'Bool');
}

{ 
  my $ds = { bool => 1, arr => [ 1, 0 ], obj => { a => 1, b => 0 } };
  my $model = TestModel->new($ds);

  cmp_ok($model->bool, '==', 1);
  cmp_ok($model->arr->[0], '==', 1);
  cmp_ok($model->arr->[1], '==', 0);
  cmp_ok($model->obj->{a}, '==', 1);
  cmp_ok($model->obj->{b}, '==', 0);
}

{ 
  use JSON::MaybeXS;
  
  my $ds = decode_json('{"bool":true,"arr":[true,false],"obj":{"a":true,"b":false}}');
  my $model = TestModel->new($ds);

  cmp_ok($model->bool, '==', 1);
  cmp_ok($model->arr->[0], '==', 1);
  cmp_ok($model->arr->[1], '==', 0);
  cmp_ok($model->obj->{a}, '==', 1);
  cmp_ok($model->obj->{b}, '==', 0);
}

done_testing;
