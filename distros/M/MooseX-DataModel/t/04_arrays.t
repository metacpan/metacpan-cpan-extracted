#!/usr/bin/env perl

use Test::More;
use Test::Exception;

package TestModel {
  use MooseX::DataModel;
  array arr1 => (isa => 'Int');
  array arr2 => (isa => 'TestArr2');
}

package TestArr2 {
  use MooseX::DataModel;
  key name => (isa => 'Str');
  key value => (isa => 'Str');
}


{ 
  my $ds = { arr1 => [ 1, 2, 3 ] };
  my $model1 = TestModel->new($ds);

  is_deeply($model1->arr1, [ 1, 2, 3 ]);
}

{ 
  my $ds = { arr2 => [ { name => 'pepe', value => 'grillo' } ] };
  my $model1 = TestModel->new($ds);

  isa_ok($model1->arr2->[0], 'TestArr2');
  cmp_ok($model1->arr2->[0]->name, 'eq', 'pepe'); 
  cmp_ok($model1->arr2->[0]->value, 'eq', 'grillo'); 
}

done_testing;
