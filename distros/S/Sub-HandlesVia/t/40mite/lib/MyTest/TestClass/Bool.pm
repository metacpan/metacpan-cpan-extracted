package MyTest::TestClass::Bool;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'Bool',
  handles_via => 'Bool',
  handles => {
    'my_not' => 'not',
    'my_reset' => 'reset',
    'my_set' => 'set',
    'my_toggle' => 'toggle',
    'my_unset' => 'unset',
  },
  default => sub { 0 },
);

1;

