#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 37;

use Pinwheel::Cache qw(cache cache_clear cache_get cache_remove cache_set);
use Pinwheel::Cache::Null;
use Pinwheel::Cache::Hash;


# Null backend does no caching
{
    Pinwheel::Cache::set_backend(new Pinwheel::Cache::Null);

    ok(!cache_set('v', 'test'));
    ok(!cache_set('v', 'test', 3600));

    is(cache_get('v'), undef);

    ok(!cache_remove('v'));

    is(cache('v', 3600, sub { 42 }), 42);
    is(cache_get('v'), undef);

    is(cache('v', sub { 42 }), 42);
    is(cache_get('v'), undef);

    ok(cache_clear());
}

# A simple hash backend
{
    Pinwheel::Cache::set_backend(new Pinwheel::Cache::Hash);

    ok(cache_set('v1', 'value1'));
    ok(cache_set('v2', 'value2', 3600));

    is(cache_get('v1'), 'value1');
    is(cache_get('v2'), 'value2');
    is(cache_get('v9'), undef);

    ok(cache_remove('v1'));
    ok(!cache_remove('v9'));
    is(cache_get('v1'), undef);
    
    ok(cache_clear());
    is(cache_get('v1'), undef);
    is(cache_get('v2'), undef);

    is(cache('v1', 3600, sub { 'test' }), 'test');
    is(cache_get('v1'), 'test');

    is(cache('v9', sub { 'test' }), 'test');
    is(cache_get('v9'), 'test');
}

# Null backend can be restored
{
    Pinwheel::Cache::set_backend();

    ok(!cache_set('v1', 'test'));
    ok(!cache_set('v1', 'test', 3600));

    is(cache_get('v'), undef);
}

# "cache" wrapper
{
    Pinwheel::Cache::set_backend(new Pinwheel::Cache::Hash);

    ok(cache_clear());
    is(cache('v1', sub { 'test' }), 'test');
    is(cache_get('v1'), 'test');
    is(cache('v1', sub { 'foo' }), 'test');
    is(cache_get('v1'), 'test');

    ok(cache_clear());
    is(cache('v1', sub { 60 }, sub { 'test' }), 'test');
    is(cache_get('v1'), 'test');
    is(cache('v1', sub { 90 }, sub { 'foo' }), 'test');
    is(cache_get('v1'), 'test');
}

# FIXME: check to see if port 11211 is open and skip tests if it is closed
#
# use Pinwheel::Cache::Memcached;
#
# Memcached tests
# {
#     Pinwheel::Cache::set_backend(new Pinwheel::Cache::Memcached);
# 
#     ok(cache_set('v1', 'value1'));
#     ok(cache_set('v2', 'value2', 3600));
# 
#     is(cache_get('v1'), 'value1');
#     is(cache_get('v2'), 'value2');
#     is(cache_get('v9'), undef);
# 
#     ok(cache_remove('v1'));
#     ok(!cache_remove('v9'));
#     is(cache_get('v1'), undef);
#     
#     ok(cache_clear());
#     is(cache_get('v1'), undef);
#     is(cache_get('v2'), undef);
# 
#     is(cache('v1', 3600, sub { 'test' }), 'test');
#     is(cache_get('v1'), 'test');
# 
#     is(cache('v9', sub { 'test' }), 'test');
#     is(cache_get('v9'), 'test');
# }
