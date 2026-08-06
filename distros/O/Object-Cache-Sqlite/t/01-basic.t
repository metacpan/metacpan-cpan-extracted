use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp;

# Create temp directory for test databases
my $tmp = File::Temp->newdir('obj_cache_sqlite_test_XXXX');

# Test 1: Module loads
use_ok('Object::Cache::Sqlite');

# Test 2: Constructor requires db_file
eval { Object::Cache::Sqlite->new() };
like($@, qr/db_file is required/, 'Constructor requires db_file');

# Test 3: Create cache object
my $db_file = File::Spec->catfile("$tmp", 'test.sqlite');
my $cache = Object::Cache::Sqlite->new(db_file => $db_file);
isa_ok($cache, 'Object::Cache::Sqlite');

# Test 4: Database file created
ok(-f $db_file, 'Database file created');

# Test 5: Set and get a string
ok($cache->set('key1', 'value1'), 'Set string value');
is($cache->get('key1'), 'value1', 'Get string value');

# Test 6: Set and get an integer
ok($cache->set('key2', 42), 'Set integer value');
is($cache->get('key2'), 42, 'Get integer value');

# Test 7: Set and get an array reference
my $array_ref = [1, 2, 3, 'hello'];
ok($cache->set('key3', $array_ref), 'Set array reference');
is_deeply($cache->get('key3'), $array_ref, 'Get array reference');

# Test 8: Set and get a hash reference
my $hash_ref = { name => 'John', age => 30, active => 1 };
ok($cache->set('key4', $hash_ref), 'Set hash reference');
is_deeply($cache->get('key4'), $hash_ref, 'Get hash reference');

# Test 9: Overwrite existing key
ok($cache->set('key1', 'new_value'), 'Overwrite existing key');
is($cache->get('key1'), 'new_value', 'Get overwritten value');

# Test 10: Get non-existent key
is($cache->get('nonexistent'), undef, 'Get non-existent key returns undef');

# Test 11: Delete key
ok($cache->delete('key2'), 'Delete key');
is($cache->get('key2'), undef, 'Deleted key returns undef');

# Test 12: Cached item count
my $count = $cache->cached_item_count();
is($count, 3, 'Cached item count is correct');

# Test 13: Cached item keys
my $keys = $cache->cached_item_keys();
is(ref($keys), 'ARRAY', 'Cached item keys returns array reference');
is(scalar @$keys, 3, 'Cached item keys has correct count');

# Test 14: Empty cache
my $deleted = $cache->empty_cache();
is($deleted, 3, 'Empty cache returns deleted count');
is($cache->cached_item_count(), 0, 'Cache is empty after empty_cache');

# Test 15: Init DB
ok($cache->init_db(), 'Init DB succeeds');
is($cache->cached_item_count(), 0, 'Cache is empty after init_db');

done_testing();
