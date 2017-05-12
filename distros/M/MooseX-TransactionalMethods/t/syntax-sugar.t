#!/usr/bin/perl
use Test::More;

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
  use MooseX::TransactionalMethods;

  has schema => (is => 'ro');

  transactional bla => sub {
      my $self = shift;
      return 'return '.shift;
  };
}

{ package My::ClassTest2;
  use MooseX::TransactionalMethods;

  transactional bla => $schema, sub {
      my ($self, $data) = @_;
      return 'return '.$data;
  };
}

my $object1 = My::ClassTest1->new({ schema => $schema });
my $object2 = My::ClassTest2->new();

is($object1->bla('test1'),'txn_do return test1',
   'fetching the schema from the instance.');

is($object2->bla('test2'),'txn_do return test2',
   'using the schema in the declaration.');

done_testing();


