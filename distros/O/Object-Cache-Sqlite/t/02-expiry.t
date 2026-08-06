use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp;

# Create temp directory for test databases
my $tmp = File::Temp->newdir('obj_cache_sqlite_expiry_test_XXXX');

use Object::Cache::Sqlite;

# Create cache object
my $db_file = File::Spec->catfile("$tmp", 'expiry.sqlite');
my $cache = Object::Cache::Sqlite->new(db_file => $db_file);

# Test 1: Set with relative TTL (1 second)
ok($cache->set('short_lived', 'data', 1), 'Set with 1 second TTL');

# Test 2: Value exists immediately
is($cache->get('short_lived'), 'data', 'Value exists immediately after set');

# Test 3: Wait for expiration
diag('Sleeping 2 seconds to test expiration...');
sleep 2;

# Test 4: Expired value returns undef
is($cache->get('short_lived'), undef, 'Expired value returns undef');

# Test 5: Set with absolute timestamp in the past
my $past_time = time() - 100;
is($cache->set('past_expiry', 'old data', $past_time), 0, 'Set with past absolute timestamp');

# Test 6: Past timestamp value returns undef
is($cache->get('past_expiry'), undef, 'Past timestamp value returns undef');

# Test 7: Set with far future timestamp
my $future_time = time() + 3600;
ok($cache->set('future_expiry', 'future data', $future_time), 'Set with future absolute timestamp');

# Test 8: Future timestamp value exists
is($cache->get('future_expiry'), 'future data', 'Future timestamp value exists');

# Test 9: Count after cleanup
my $count = $cache->cached_item_count();
is($count, 1, 'Count is correct after cleanup');

done_testing();
