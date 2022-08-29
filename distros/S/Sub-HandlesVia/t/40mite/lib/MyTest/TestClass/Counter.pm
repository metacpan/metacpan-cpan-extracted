package MyTest::TestClass::Counter;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'Int',
  handles_via => 'Counter',
  handles => {
    'my_dec' => 'dec',
    'my_inc' => 'inc',
    'my_reset' => 'reset',
    'my_set' => 'set',
  },
  default => sub { 0 },
);

1;

