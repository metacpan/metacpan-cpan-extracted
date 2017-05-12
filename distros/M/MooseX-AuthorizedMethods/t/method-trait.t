#!/usr/bin/perl
use Test::More;

use_ok('MooseX::Meta::Method::Authorized');

use Moose;
my $method_metaclass = Moose::Meta::Class->create_anon_class
  (
   superclasses => ['Moose::Meta::Method'],
   roles => ['MooseX::Meta::Method::Authorized'],
   cache => 1,
  );

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
  use Moose;
  has 'user' => (is => 'ro', required => 1);

  my $m = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return 'return '.shift;
     },
     package_name => 'My::ClassTest1',
     name => 'bla',
     requires => ['foo']
    );
  __PACKAGE__->meta->add_method('bla',$m);

  my $n = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return 'return '.shift;
     },
     package_name => 'My::ClassTest1',
     name => 'boo',
     requires => ['gah']
    );
  __PACKAGE__->meta->add_method('boo',$n);

};

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
