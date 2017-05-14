#!/usr/bin/env perl

use Test::More;
use Test::Exception;

package TestModel {
  use MooseX::DataModel;
  key att1 => (isa => 'Str', location => 'keyLoc');
  array att2 => (isa => 'Str', location => 'arrayLoc');
  object att3 => (isa => 'Str', location => 'hashLoc');
  key ref => (isa => 'Str', location => '$ref');
}

{ 
  my $ds = { att1 => 'is there' };
  my $model1 = TestModel->new($ds);

  ok(not(defined($model1->att1)), 'att2 should only be assigned via customLoc, not att2');
}

{ 
  my $ds = { keyLoc => 'is there' };
  my $model1 = TestModel->new($ds);

  cmp_ok($model1->att1, 'eq', 'is there');
}

{
  my $ds = { arrayLoc => [ 'is there' ] };
  my $model1 = TestModel->new($ds);

  cmp_ok($model1->att2->[0], 'eq', 'is there');
}

{ 
  my $ds = { att2 => [ 'is there' ] };
  my $model1 = TestModel->new($ds);

  ok(not(defined($model1->att2)), 'att2 should only be assigned via arrayLoc, not att2');
}

{
  my $ds = { hashLoc => { k1 => 'is there' } };
  my $model1 = TestModel->new($ds);

  cmp_ok($model1->att3->{ k1 }, 'eq', 'is there');
}

{ 
  my $ds = { att3 => { k1 => 'is there' } };
  my $model1 = TestModel->new($ds);

  ok(not(defined($model1->att3)), 'att3 should only be assigned via hashLoc, not att3');
}

{
  my $ds = { '$ref' => 'is there' };
  my $model1 = TestModel->new($ds);

  cmp_ok($model1->ref, 'eq', 'is there');
}



done_testing;
