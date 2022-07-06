package MyTest::TestClass::Code;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'CodeRef',
  handles_via => 'Code',
  handles => {
    'my_execute' => 'execute',
    'my_execute_method' => 'execute_method',
  },
  default => sub { sub {} },
);

1;

