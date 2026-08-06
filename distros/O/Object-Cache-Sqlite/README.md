## NAME

Object::Cache::Sqlite - SQLite-based object cache with automatic expiration

## SYNOPSIS

```perl
use Object::Cache::Sqlite;

my $cache = Object::Cache::Sqlite->new(
    db_file => '/tmp/cache.sqlite',
);

my $scalar   = 42;
my $list_ref = [ 1, 3, 5, 7, 9 ];
my $hash_ref = { name => 'John', email => 'john@example.com' };

my $cache_key = "user:123";

# Store some data for 15 minutes
$cache->set('age'     , $scalar  , time() + 900);
$cache->set('ids'     , $list_ref, time() + 900);
$cache->set($cache_key, $hash_ref, time() + 900);

# Retrieve a value
my $user = $cache->get($cache_key);

# Delete a value
$cache->delete($cache_key);

# Get cache statistics
my $count = $cache->cached_item_count();
my $keys  = $cache->cached_item_keys();

# Cleanup expired entries
$cache->remove_expired_entries();

# Clear entire cache
$cache->empty_cache();
```

## DESCRIPTION

Object::Cache::Sqlite provides a simple, fast object cache backed by SQLite.
Data is automatically expired based on TTL values. Uses Cpanel::JSON::XS
for fast, portable serialization.

## CONSTRUCTOR

### new(%args)

Creates a new cache object. Required arguments:

- db\_file

    Path to the SQLite database file. The file will be created if it doesn't exist.

Optional arguments:

- silent

    If true, suppresses initialization messages. Default: 1

## METHODS

### get($key)

Retrieves a cached value by key. Returns `undef` if the key doesn't exist or
has expired.

### set($key, $value, $expires)

Stores a value in the cache. `$expires` is the time-to-live in seconds.
If `$expires` is less than 100000, it's treated as relative (seconds from now).
If `$expires` is 100000 or greater, it's treated as an absolute Unix timestamp.

Returns true on success.

### delete($key)

Removes a single entry from the cache. Returns true on success.

### cached\_item\_count()

Returns the number of non-expired entries in the cache.

### cached\_item\_keys()

Returns an arrayref of all non-expired cache keys.

### remove\_expired\_entries($vacuum)

Deletes all expired entries from the cache. If `$vacuum` is true (default),
runs SQLite `VACUUM` to reclaim space.

### empty\_cache()

Deletes ALL entries from the cache and runs `VACUUM`. Returns the number
of deleted entries.

## EXPIRATION

Cache entries can have two types of expiration:

- Relative TTL

    Values less than 100000 are treated as seconds from now.

- Absolute timestamp

    Values 100000 or greater are treated as Unix timestamps.

Expired entries are automatically cleaned up on cache hits and can be
manually cleaned with remove\_expired\_entries().

## SEE ALSO

- Cache::File::Simple

    A simple file-based cache that stores serialized data in individual files.

## AUTHOR

Scott Baker - https://www.perturb.org/

## LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Scott Baker.

This is free software; you can redistribute it and/or modify it under
the terms of the MIT License.
