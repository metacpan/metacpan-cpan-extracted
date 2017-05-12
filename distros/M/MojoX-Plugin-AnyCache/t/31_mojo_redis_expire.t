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

# FIXME should clear redis, not choose a random key
# this could still fail!
my $key = rand(10000000);

my $sync = 0;
$cache->get($key, sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$sync = 0;
$cache->set($key => 'bar', 1, sub { ok(1, 'callback is called on set with ttl in async mode'); Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$sync = 0;
$cache->get($key, sub { is shift, 'bar', 'set key with ttl returns correct value in async mode'; Mojo::IOLoop->stop; $sync = 1 });
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$sync = 0;
Mojo::IOLoop->timer(1.5 => sub {
	$cache->get($key, sub { is shift, undef, 'key has expired using set with ttl in async mode'; Mojo::IOLoop->stop; $sync = 1 });
});
is $sync, 0, 'call was asynchronous';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing(11);
