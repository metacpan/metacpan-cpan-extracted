#!/usr/bin/perl
use Test::More;

{ package My::SchemaTest;
  use Moose;
  has name => (is => 'ro');
  sub txn_do {
      my $self = shift;
      my $code = shift;
      return $self->name.' '.$code->(@_);
  }
};

my $schema1 = My::SchemaTest->new({ name => 'schema1' });
my $schema2 = My::SchemaTest->new({ name => 'schema2' });

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
  use Sub::Name;
  extends 'My::ClassTest1';
  use mro 'c3';

  transactional bla => $schema2,  sub {
      my ($self, $data) = @_;
      return 'return '.$self->next::method($data);
  };
}

{ package My::ClassTest3;
  use MooseX::TransactionalMethods;
  use Sub::Name;
  extends 'My::ClassTest1';
  use mro 'c3';

  transactional bla => sub {
      my ($self, $data) = @_;
      return 'return '.$self->next::method($data);
  };
}

my $object1 = My::ClassTest1->new({ schema => $schema1 });
my $object2 = My::ClassTest2->new({ schema => $schema1 });
my $object3 = My::ClassTest3->new({ schema => $schema2 });

is($object1->bla('test1'),'schema1 return test1',
   'fetching the schema from the instance.');

is($object2->bla('test2'),'schema2 return schema1 return test2',
   'invoking in the subclass with the schema in the declarator.');

is($object3->bla('test2'),'schema2 return schema2 return test2',
   'invoking in the subclass with the schema in the class.');

done_testing();


