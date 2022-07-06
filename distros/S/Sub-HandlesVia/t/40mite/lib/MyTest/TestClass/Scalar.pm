package MyTest::TestClass::Scalar;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'Any',
  handles_via => 'Scalar',
  handles => {
    'my_make_getter' => 'make_getter',
    'my_make_setter' => 'make_setter',
    'my_scalar_reference' => 'scalar_reference',
  },
  default => sub { q[] },
);

1;

