#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use Moose::Util::TypeConstraints;

subtype 'TestModel::StrStartsWithA', as 'Str', where { $_ =~ m/^a/ };
enum 'TestModel::Enum', [ 'Valid' ];

package TestModel {
  use MooseX::DataModel;
  #Test restricting attributes to subtypes
  key att1 => (isa => 'TestModel::StrStartsWithA');
  array att2 => (isa => 'TestModel::StrStartsWithA');
  object att3 => (isa => 'TestModel::StrStartsWithA');

  #Assure that enums are supported too...
  key att4 => (isa => 'TestModel::Enum');

  # Test to see if we can declare a class more than one time
  # (so that creating a duplicated coercion doesn't make the class
  # creation fail
  key class1 => (isa => 'TestModel::Class');
  key class2 => (isa => 'TestModel::Class');
}

package TestModel::Class {
  use MooseX::DataModel;
  key att1 => (isa => 'Str');
}

{ 
  my $ds = { att1 => 'is invalid' };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

{ 
  my $ds = { att1 => 'a value that starts with a' };

  lives_ok(sub {
    TestModel->new($ds);
  });
}

{
  my $ds = { att2 => [ 'is invalid' ] };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

{
  my $ds = { att2 => [ 'a value that starts with a' ] };

  lives_ok(sub {
    TestModel->new($ds);
  });
}

{
  my $ds = { att3 => { k1 => 'is invalid' } };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

{
  my $ds = { att3 => { k1 => 'a value that starts with a' } };

  lives_ok(sub {
    TestModel->new($ds);
  });
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
