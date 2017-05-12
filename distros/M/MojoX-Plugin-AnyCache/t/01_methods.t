#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

package FakeApp;

	use Mojo::Base -base;
	use Test::More;
	sub helper {
		my ($self, $helper, $sub) = @_;
		ok(1, 'helper is called');
		is($helper, 'cache', 'cache helper is registered');
		isa_ok($sub->(), 'MojoX::Plugin::AnyCache', 'cache object is returned by helper sub');
	}

package main;

lives_ok { $cache->register(FakeApp->new, { foo => 'bar' }) } 'register call successful';

isa_ok $cache->app, 'FakeApp', 'application is stored correctly';
is_deeply $cache->config, { foo => 'bar' }, 'plugin config is stored correctly';

dies_ok { $cache->get('foo') } 'cache get dies without backend';
like $@, qr/^No backend available/;

dies_ok { $cache->set('foo' => 'bar') } 'cache set dies without backend';
like $@, qr/^No backend available/;

dies_ok { $cache->ttl('foo') } 'cache ttl dies without backend';
like $@, qr/^No backend available/;

dies_ok { $cache->increment('foo' => 1) } 'cache increment dies without backend';
like $@, qr/^No backend available/;
dies_ok { $cache->incr('foo' => 1) } 'cache incr dies without backend';
like $@, qr/^No backend available/;

dies_ok { $cache->decrement('foo' => 1) } 'cache decrement dies without backend';
like $@, qr/^No backend available/;
dies_ok { $cache->decr('foo' => 1) } 'cache decr dies without backend';
like $@, qr/^No backend available/;

dies_ok { $cache->delete('foo') } 'cache delete dies without backend';
like $@, qr/^No backend available/;
dies_ok { $cache->del('foo') } 'cache del dies without backend';
like $@, qr/^No backend available/;

done_testing(26);
