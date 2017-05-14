#!/usr/bin/env perl

use Test::More;
use Test::Exception;

package TestKeyNotRequired {
  use MooseX::DataModel;
  key att1 => ( isa => 'Str');
}

package TestKeyRequired {
  use MooseX::DataModel;
  key att1 => ( required => 1, isa => 'Str');
}

package TestArrayNotRequired {
  use MooseX::DataModel;
  array att1 => ( isa => 'Str');
}

package TestArrayRequired {
  use MooseX::DataModel;
  array att1 => ( required => 1, isa => 'Str');
}


{ 
  my $ds = { att1 => 'is there' };

  my $model1 = TestKeyNotRequired->new($ds);
  cmp_ok($model1->att1, 'eq', 'is there');

  my $model2 = TestKeyRequired->new($ds);
  cmp_ok($model2->att1, 'eq', 'is there');
}

{ 
  my $ds = { };

  my $model1 = TestKeyNotRequired->new($ds);
  ok(not(defined($model1->att1)), 'att1 is not defined');

  dies_ok(sub { TestKeyRequired->new($ds) });
}

{
  my $ds = { att1 => [ 'is there' ] };

  my $model1 = TestArrayNotRequired->new($ds);
  cmp_ok($model1->att1->[0], 'eq', 'is there');

  my $model2 = TestArrayRequired->new($ds);
  cmp_ok($model2->att1->[0], 'eq', 'is there');
}

{ 
  my $ds = { };

  my $model1 = TestArrayNotRequired->new($ds);
  ok(not(defined($model1->att1)), 'att1 is not defined');

  dies_ok(sub { TestArrayRequired->new($ds) });
}




done_testing;
