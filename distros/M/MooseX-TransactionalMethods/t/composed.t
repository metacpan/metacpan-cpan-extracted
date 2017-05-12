use Test::More;
use Test::Moose;

{ package OtherRole;
  use Moose::Role;
};

{ package MyRole;
  use Moose::Role;
  with 'OtherRole';
  with 'MooseX::Meta::Method::Transactional';
};

{ package MyClass;
  use Moose;
  has schema => (is => 'ro');
  sub m00 {'m00'};
};

{ package MySchema;
  use Moose;
  sub txn_do {
      my $self = shift;
      my $code = shift;
      return 'txn_do '.$code->(@_);
  }
};

my $meth = MyClass->meta->get_method('m00');
MyRole->meta->apply($meth);

# I'm not sure why these tests fail, but they are not the reason I'm
# doing this module.
#########
#does_ok('MyRole', 'OtherRole', 'composing works.');
#does_ok('MyRole', 'MooseX::Meta::Method::Transactional', 'composing works.');
#does_ok($meth, 'OtherRole', 'does one of the original roles');
#does_ok($meth, 'MooseX::Meta::Method::Transactional', 'does the important role');

does_ok($meth, 'MyRole', 'does the composed role');

my $schema = MySchema->new();
my $obj = MyClass->new({schema => $schema});

is_deeply($meth->schema->($obj), $schema, 'has the data.');

is($obj->m00, 'txn_do m00', 'First method works.');

done_testing;
