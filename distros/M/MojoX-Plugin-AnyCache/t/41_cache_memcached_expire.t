#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

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

# FIXME should clear memcached, not choose a random key
# this could still fail!
my $key = rand(10000000);

is $cache->get($key), undef, 'unset key returns undef in sync mode';
$cache->set($key => 'bar', 1);
is $cache->get($key), 'bar', 'set key with ttl returns correct value in sync mode';
sleep 2;
is $cache->get($key), undef, 'key has expired using set with ttl in async mode';


done_testing(6);
