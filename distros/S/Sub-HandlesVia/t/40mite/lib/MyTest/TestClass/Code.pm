package MyTest::TestClass::Code;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'CodeRef',
  handles_via => 'Code',
  handles => {
    'my_execute' => 'execute',
    'my_execute_list' => 'execute_list',
    'my_execute_method' => 'execute_method',
    'my_execute_method_list' => 'execute_method_list',
    'my_execute_method_scalar' => 'execute_method_scalar',
    'my_execute_method_void' => 'execute_method_void',
    'my_execute_scalar' => 'execute_scalar',
    'my_execute_void' => 'execute_void',
  },
  default => sub { sub {} },
);

1;

