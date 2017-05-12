#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

unless($ENV{'CACHE_TEST_REDIS'}) {
	plan skip_all => 'Redis tests skipped - set CACHE_TEST_REDIS to run tests'
}

package FakeApp;
	use Mojo::Base -base;
	sub helper {}

package main;

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

my %opts = ();
$opts{server} = $ENV{'CACHE_TEST_REDIS_HOST'} if $ENV{'CACHE_TEST_REDIS_HOST'};
$cache->register(FakeApp->new, { backend => 'MojoX::Plugin::AnyCache::Backend::Mojo::Redis', %opts });
isa_ok $cache->backend, 'MojoX::Plugin::AnyCache::Backend::Mojo::Redis';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';
can_ok $cache->backend, 'incr';
can_ok $cache->backend, 'decr';
can_ok $cache->backend, 'del';
can_ok $cache->backend, 'ttl';

# FIXME should clear redis, not choose a random key
# this could still fail!
my $key = rand(10000000);

my $sync = 0;
$cache->get($key, sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$sync = 0;
$cache->set($key => 'bar', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$sync = 0;
$cache->get($key, sub { is shift, 'bar', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Set with TTL
$sync = 0;
$cache->set('ruuv' => 'baz', 5, sub { ok(1, 'callback is called on set with ttl in async mode'); Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$sync = 0;
$cache->ttl('ruuv', sub { is shift, 5, 'set key with ttl returns correct ttl value in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$sync = 0;
$cache->get('ruuv', sub { is shift, 'baz', 'set key with ttl returns correct value in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Increment (asynchronous)
$sync = 0;
$cache->incr('ruux', 1, sub { ok 1, 'callback is called on incr in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$sync = 0;
$cache->get('ruux', sub { is shift, 1, 'increment completed successfully in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Increment (asynchronous)
$sync = 0;
$cache->incr('ruux', 5, sub { ok 1, 'callback is called on incr >1 in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$sync = 0;
$cache->get('ruux', sub { is shift, 6, 'increment >1 completed successfully in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Decrement (asynchronous)
$sync = 0;
$cache->decr('ruux', 5, sub { ok 1, 'callback is called on decr >1 in async mode'; Mojo::IOLoop->stop });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$sync = 0;
$cache->get('ruux', sub { is shift, 1, 'decrement >1 completed successfully in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Decrement (asynchronous)
$sync = 0;
$cache->decr('ruux', 1, sub { ok 1, 'callback is called on decr in async mode'; Mojo::IOLoop->stop });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$sync = 0;
$cache->get('ruux', sub { is shift, 0, 'decrement completed successfully in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Delete (asynchronous)
$sync = 0;
$cache->del('ruux', sub { ok 1, 'callback is called on del in async mode'; Mojo::IOLoop->stop });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$sync = 0;
$cache->get('ruux', sub { is shift, undef, 'delete completed successfully in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing(41);
