#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use Moose::Util::TypeConstraints;

package AnObject {
  use MooseX::DataModel;
  key a => (isa => 'Str');
}

coerce 'AnObject',
  from 'HashRef',
   via { AnObject->new(a => "coerced " . $_->{ a }) };

package TestModel {
  use MooseX::DataModel;
  key att1 => (isa => 'AnObject');
  array att2 => (isa => 'AnObject');
  object att3 => (isa => 'AnObject');
}

{ 
  my $ds = { att1 => { a => 'val1' }, att2 => [ { a => 'val2' } ], att3 => { 'key1' => { 'a' => 'val3' } } };
  my $model = TestModel->new($ds);

  cmp_ok($model->att1->a, 'eq', 'coerced val1');
  cmp_ok($model->att2->[0]->a, 'eq', 'coerced val2');
  cmp_ok($model->att3->{key1}->a, 'eq', 'coerced val3');
}

done_testing;
