package MyTest::TestClass::Number;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'Num',
  handles_via => 'Number',
  handles => {
    'my_abs' => 'abs',
    'my_add' => 'add',
    'my_cmp' => 'cmp',
    'my_div' => 'div',
    'my_eq' => 'eq',
    'my_ge' => 'ge',
    'my_get' => 'get',
    'my_gt' => 'gt',
    'my_le' => 'le',
    'my_lt' => 'lt',
    'my_mod' => 'mod',
    'my_mul' => 'mul',
    'my_ne' => 'ne',
    'my_set' => 'set',
    'my_sub' => 'sub',
  },
  default => sub { 0 },
);

1;

