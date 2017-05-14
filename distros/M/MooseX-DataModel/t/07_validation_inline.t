#!/usr/bin/env perl

use Test::More;
use Test::Exception;


package TestModel {
  use MooseX::DataModel;

  key att1 => (isa => subtype as 'Str', where { $_ =~ m/^a/ });
  array att2 => (isa => subtype as 'Str', where { $_ =~ m/^a/ });
  object att3 => (isa => subtype as 'Str', where { $_ =~ m/^a/ });

  key att4 => (isa => enum([ 'Valid' ]));

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
