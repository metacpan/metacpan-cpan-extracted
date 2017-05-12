#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

unless($ENV{'CACHE_TEST_MEMCACHED'}) {
	plan skip_all => 'Memcached tests skipped - set CACHE_TEST_MEMCACHED to run tests'
}

package FakeApp;
	use Mojo::Base -base;
	sub helper {}

package main;

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

$cache->register(FakeApp->new, { backend => 'MojoX::Plugin::AnyCache::Backend::Cache::Memcached', servers => [ "127.0.0.1:11211" ] });
isa_ok $cache->backend, 'MojoX::Plugin::AnyCache::Backend::Cache::Memcached';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';
can_ok $cache->backend, 'incr';
can_ok $cache->backend, 'decr';
can_ok $cache->backend, 'del';
can_ok $cache->backend, 'ttl';

# FIXME should clear memcached, not choose a random key
# this could still fail!
my $key = rand(10000000);

my $sync = 0;
is $cache->get($key), undef, 'unset key returns undef in sync mode';
$cache->set($key => 'bar');
is $cache->get($key), 'bar', 'set key returns correct value in sync mode';

dies_ok { $cache->ttl('foo') } 'cache ttl dies without get_ttl_support enabled';
like $@, qr/^get_ttl_support not enabled/;

$cache->backend->get_ttl_support(1);
$cache->set('foo' => 1, 5);
lives_ok { $cache->ttl('foo') } 'cache ttl succeeds with get_ttl_support enabled';

$cache->set('ruux' => 1, 5);
is $cache->ttl('ruux'), 5, 'ttl returns correct value in sync mode';
is $cache->get('ruux'), 1, 'set with ttl returns correct value in sync mode';

# Set starting value for memcached
$cache->set('quux', 0);

# Increment (synchronous)
$cache->incr('quux', 1);
is $cache->get('quux'), 1, 'cache returns correct incr value in sync mode';

# Increment (synchronous) >1
$cache->incr('quux', 5);
is $cache->get('quux'), 6, 'cache returns correct incr >1 value in sync mode';

# Decrement (synchronous) >1
$cache->decr('quux', 5);
is $cache->get('quux'), 1, 'cache returns correct decr >1 value in sync mode';

# Decrement (synchronous)
$cache->decr('quux', 1);
is $cache->get('quux'), 0, 'cache returns correct decr value in sync mode';

# Delete (synchronous)
$cache->del('quux');
is $cache->get('quux'), undef, 'cache deletes value in sync mode';

done_testing(21);
