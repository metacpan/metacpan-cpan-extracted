#!/usr/bin/env perl

use Test::More;
use Test::Exception;

package TestModel {
  use MooseX::DataModel;
  object obj1 => (isa => 'Int');
  object obj2 => (isa => 'TestObj2');
}

package TestObj2 {
  use MooseX::DataModel;
  key name => (isa => 'Str');
  key value => (isa => 'Str');
}


SKIP: {
  skip "Automatically attached traits to a model is not implemented yet", 2;
  my $ds = { obj1 => { k1 => 1, k2 => 2, k3 => 3 } };
  my $model1 = TestModel->new($ds);

  is_deeply([ sort $model->obj1_keys ], [ 'k1', 'k2', 'k3' ]); 
  cmp_ok($model->get_obj1('k1'), '==', 1);
}

SKIP:{ 
  skip "Automatically attached traits to a model is not implemented yet", 2;
  my $ds = { obj2 => { k1 => { name => 'pepe', value => 'grillo' },
                       k2 => { name => 'manuel', value => 'juan' }
                     }
           };
  my $model1 = TestModel->new($ds);

  is_deeply([ sort $model->obj2_keys ], [ 'k1', 'k2' ]); 
  cmp_ok($model->get_obj2('k1')->name, 'eq', 'pepe');
}

done_testing;
