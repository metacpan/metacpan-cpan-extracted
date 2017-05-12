#!/usr/bin/perl
use Test::More;

use_ok('MooseX::Meta::Method::Transactional');

use Moose;
my $method_metaclass = Moose::Meta::Class->create_anon_class
  (
   superclasses => ['Moose::Meta::Method'],
   roles => ['MooseX::Meta::Method::Transactional'],
   cache => 1,
  );

{ package My::SchemaTest;
  use Moose;
  sub txn_do {
      my $self = shift;
      my $code = shift;
      return 'txn_do '.$code->(@_);
  }
};

my $schema = My::SchemaTest->new();

{ package My::ClassTest1;
  use Moose;
  has 'schema' => (is => 'ro', required => 1);
  my $m = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return 'return '.shift;
     },
     package_name => 'My::ClassTest1',
     name => 'bla'
    );
  __PACKAGE__->meta->add_method('bla',$m);
};

{ package My::ClassTest2;
  use Moose;
  my $m = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return 'return '.shift;
     },
     package_name => 'My::ClassTest2',
     name => 'bla',
     schema => $schema
    );
  __PACKAGE__->meta->add_method('bla',$m);
};

my $object1 = My::ClassTest1->new({ schema => $schema });
my $object2 = My::ClassTest2->new();

is($object1->bla('test1'),'txn_do return test1',
   'fetching the schema from the instance.');

is($object2->bla('test2'),'txn_do return test2',
   'using the schema in the declaration.');

done_testing();

1;
