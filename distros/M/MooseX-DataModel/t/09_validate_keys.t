#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use Moose::Util::TypeConstraints;

package TestModel {
  use MooseX::DataModel;

  object att1 => (isa => 'Str', key_isa => sub { $_[0] =~ m/^key\d+/ });
  object att2 => (isa => 'Str', key_isa => 'Int');
}

TODO: {
  local $TODO = 'Key validation not implemented yet'; 
  my $ds = {
    att1 => {
      key1 => 'value1',
      key2 => 'value2',
      key3 => 'value3',
    }
  };

  lives_ok(sub {
    TestModel->new($ds);
  });
}

TODO: {
  local $TODO = 'Key validation not implemented yet'; 

  my $ds = {
    att1 => {
      invalid1 => 'value1',
      key2 => 'value2',
      key3 => 'value3',
    }
  };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

TODO: {
  local $TODO = 'Key validation not implemented yet'; 

  my $ds = {
    att2 => {
      1 => 'value1',
      2 => 'value2',
      3 => 'value3',
    }
  };

  lives_ok(sub {
    TestModel->new($ds);
  });
}

TODO: {
  local $TODO = 'Key validation not implemented yet'; 

  my $ds = {
    att2 => {
      v1 => 'value1',
      2 => 'value2',
      3 => 'value3',
    }
  };

  dies_ok(sub {
    TestModel->new($ds);
  });
}

done_testing;
