use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp;

# Create temp directory for test databases
my $tmp = File::Temp->newdir('obj_cache_sqlite_serial_test_XXXX');

use Object::Cache::Sqlite;

# Test 1: Create cache object (default JSON serialization)
my $db_file = File::Spec->catfile("$tmp", 'cache.sqlite');
my $cache = Object::Cache::Sqlite->new(db_file => $db_file);
isa_ok($cache, 'Object::Cache::Sqlite');

# Test 2: Set and get a complex nested data structure
my $data = { nested => { deep => [1, 2, 3] } };
ok($cache->set('key1', $data), 'Set complex data');
is_deeply($cache->get('key1'), $data, 'Get complex data');

# Test 3: Set and get an undef value
ok($cache->set('undef_key', undef), 'Set undef value');
is($cache->get('undef_key'), undef, 'Get undef value');

# Test 4: Set and get an empty hash
my $empty = {};
ok($cache->set('empty_hash', $empty), 'Set empty hash');
is_deeply($cache->get('empty_hash'), $empty, 'Get empty hash');

# Test 5: Set and get an empty array
my $empty_arr = [];
ok($cache->set('empty_arr', $empty_arr), 'Set empty array');
is_deeply($cache->get('empty_arr'), $empty_arr, 'Get empty array');

done_testing();
