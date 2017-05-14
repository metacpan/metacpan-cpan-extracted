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


{ 
  my $ds = { obj1 => { k1 => 1, k2 => 2, k3 => 3 } };
  my $model1 = TestModel->new($ds);

  is_deeply($model1->obj1, { k1 => 1, k2 => 2, k3 => 3 });
}

{ 
  my $ds = { obj2 => { k1 => { name => 'pepe', value => 'grillo' },
                       k2 => { name => 'manuel', value => 'juan' }
                     }
           };
  my $model1 = TestModel->new($ds);

  isa_ok($model1->obj2->{ k1 }, 'TestObj2');
  cmp_ok($model1->obj2->{ k1 }->name, 'eq', 'pepe'); 
  cmp_ok($model1->obj2->{ k1 }->value, 'eq', 'grillo'); 

  isa_ok($model1->obj2->{ k2 }, 'TestObj2');
  cmp_ok($model1->obj2->{ k2 }->name, 'eq', 'manuel'); 
  cmp_ok($model1->obj2->{ k2 }->value, 'eq', 'juan'); 

}

done_testing;
