#!/usr/bin/perl
use Test::More;

{ package My::UserTest;
  use Moose;
  sub roles {
      return qw(foo bar baz);
  }
  sub id {
      return 'johndoe';
  }
};

my $user = My::UserTest->new();

{ package My::ClassTest1;
  use MooseX::AuthorizedMethods;

  has user => (is => 'ro');

  authorized bla => ['foo'], sub {
      my $self = shift;
      return 'return '.shift;
  };

  authorized boo => ['gah'], sub {
      my $self = shift;
      return 'return '.shift;
  };

}


my $object1 = My::ClassTest1->new({ user => $user });

is($object1->bla('test1'),'return test1',
   'fetching the schema from the instance.');

eval {
    $object1->boo('test1');
};
like($@.'',qr(Access Denied)i,
     'Dies when the user has no rights');

done_testing();

1;


