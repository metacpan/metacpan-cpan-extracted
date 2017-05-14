#!/usr/bin/env perl

use Test::More;
use Test::Exception;


package TestModel {
  use MooseX::DataModel;
  use Types::Standard qw( Str Int Enum );

  key att1 => (isa => Int);
  array att2 => (isa => Int);
  object att3 => (isa => Int);

  key att4 => (isa => Enum([ 'Valid' ]));

  key class1 => (isa => 'TestModel::Class');
  key class2 => (isa => 'TestModel::Class');
}

package TestModel::Class {
  use MooseX::DataModel;
  key att1 => (isa => 'Str');
}

{ 
  my $ds = { att1 => 'not a number' };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

{ 
  my $ds = { att1 => 42 };

  my $m;
  lives_ok(sub {
    $m = TestModel->new($ds);
  });
  cmp_ok($m->att1, '==', 42, 'att1 is 42');
}

{
  my $ds = { att2 => [ 'is invalid' ] };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

{
  my $ds = { att2 => [ 42 ] };

  my $m;
  lives_ok(sub {
    $m = TestModel->new($ds);
  });
  cmp_ok($m->att2->[0], '==', 42, 'att1->[0] is 42');
}

{
  my $ds = { att3 => { k1 => 'is invalid' } };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

{
  my $ds = { att3 => { k1 => 42 } };

  my $m;
  lives_ok(sub {
    $m = TestModel->new($ds);
  });
  cmp_ok($m->att3->{ k1 }, '==', 42, 'att3->k1 is 42');
}

{
  my $ds = { att4 => 'Invalid' };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

{
  my $ds = { att4 => 'Valid' };

  lives_ok(sub {
    TestModel->new($ds);
  });
}


done_testing;
