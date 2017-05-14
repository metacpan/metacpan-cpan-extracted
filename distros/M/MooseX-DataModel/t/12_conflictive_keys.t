#!/usr/bin/env perl

use Test::More;
use Test::Exception;


package TestModel {
  use MooseX::DataModel;

  key key => (isa => 'Str');
  key array => (isa => 'Str');
  key object => (isa => 'Str');
  key has => (isa => 'Str');
  key type => (isa => 'Str');

  no MooseX::DataModel;

  __PACKAGE__->meta->make_immutable;
}

{ 
  my $ds = { key => 'exists',
             array => 'exists',
             object => 'exists',
             has => 'exists',
             type => 'exists',
  };

  lives_ok(sub {
    TestModel->new($ds);
  });
}

#TODO: test a key named "meta"

done_testing;
