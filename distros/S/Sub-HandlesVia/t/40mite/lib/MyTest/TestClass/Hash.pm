package MyTest::TestClass::Hash;

use MyTest::Mite;
use Sub::HandlesVia;

has attr => (
  is => 'rwp',
  isa => 'HashRef',
  handles_via => 'Hash',
  handles => {
    'my_accessor' => 'accessor',
    'my_all' => 'all',
    'my_clear' => 'clear',
    'my_count' => 'count',
    'my_defined' => 'defined',
    'my_delete' => 'delete',
    'my_delete_where' => 'delete_where',
    'my_elements' => 'elements',
    'my_exists' => 'exists',
    'my_for_each_key' => 'for_each_key',
    'my_for_each_pair' => 'for_each_pair',
    'my_for_each_value' => 'for_each_value',
    'my_get' => 'get',
    'my_is_empty' => 'is_empty',
    'my_keys' => 'keys',
    'my_kv' => 'kv',
    'my_reset' => 'reset',
    'my_set' => 'set',
    'my_shallow_clone' => 'shallow_clone',
    'my_sorted_keys' => 'sorted_keys',
    'my_values' => 'values',
  },
  default => sub { {} },
);

1;

