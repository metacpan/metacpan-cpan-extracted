#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;

use File::Basename;
use lib dirname(__FILE__);
use FakeBackend;

package FakeApp;
	use Mojo::Base -base;
	sub helper {}

package main;

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

my %opts = (
	nodes => [
		{ backend => 'FakeBackend' },
		{ backend => 'FakeBackend' },
		{ backend => 'FakeBackend' },
		{ backend => 'FakeBackend' },
	]
);
$cache->register(FakeApp->new, { backend => 'MojoX::Plugin::AnyCache::Backend::Replicator', %opts });
isa_ok $cache->backend, 'MojoX::Plugin::AnyCache::Backend::Replicator';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';
can_ok $cache->backend, 'incr';
can_ok $cache->backend, 'decr';
can_ok $cache->backend, 'del';
can_ok $cache->backend, 'ttl';
is @{$cache->backend->{nodes}}, 4, 'Backend created 4 nodes';

is $cache->get('foo'), undef, 'unset key returns undef in sync mode';
$cache->set('foo' => 'bar');
is $cache->get('foo'), 'bar', 'set key returns correct value in sync mode';

for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('foo'), 'bar', "node $_ stored correct value";
}

$cache->set('roo' => 'bar', 5);
is $cache->ttl('roo'), 5, 'set key with ttl returns correct ttl in sync mode';
is $cache->get('roo'), 'bar', 'set key with ttl returns correct value in sync mode';

for (0..3) {
	is $cache->backend->{nodes}->[$_]->ttl('roo'), 5, "node $_ stored correct ttl";
	is $cache->backend->{nodes}->[$_]->get('roo'), 'bar', "node $_ stored correct value";
}

$cache->get('qux', sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set('qux' => 'bar', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('qux', sub { is shift, 'bar', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('qux'), 'bar', "node $_ stored correct value";
}

$cache->get('rux', sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set('rux' => 'bar', 5, sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->ttl('rux', sub { is shift, 5, 'set key with ttl returns correct ttl in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('rux', sub { is shift, 'bar', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

for (0..3) {
	is $cache->backend->{nodes}->[$_]->ttl('rux'), 5, "node $_ stored correct ttl";
	is $cache->backend->{nodes}->[$_]->get('rux'), 'bar', "node $_ stored correct value";
}

# Increment (synchronous)
$cache->incr('quux', 1);
is $cache->get('quux'), 1, 'cache returns correct incr value in sync mode';
for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('quux'), 1, "node $_ incremented correctly";
}

# Decrement (synchronous)
$cache->decr('quuy', 1);
is $cache->get('quuy'), -1, 'cache returns correct decr value in sync mode';
for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('quuy'), -1, "node $_ decremented correctly";
}

# Delete (synchronous)
$cache->del('quux');
is $cache->get('quuy'), -1, 'cache returns correct decr value in sync mode';
for (0..3) {
	is $cache->backend->{nodes}->[$_]->get('quuy'), -1, "node $_ decremented correctly";
}


# Increment (asynchronous)
$cache->incr('ruux', 1, sub { ok 1, 'callback is called on incr in async mode'; Mojo::IOLoop->stop });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
SKIP: {
	skip 'FIXME ->get on incr/decr value uses deserialiser', 1;
	$cache->get('ruux', sub { is 1, undef, 'incr is successful in async mode'; Mojo::IOLoop->stop; });
	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}
for (0..3) {
	$cache->backend->{nodes}->[$_]->get('ruux', sub { is shift, 1, "node $_ incremented correctly"; Mojo::IOLoop->stop; });
	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

# Decrement (asynchronous)
$cache->decr('ruuy', 1, sub { ok -1, 'callback is called on decr in async mode'; Mojo::IOLoop->stop });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
SKIP: {
	skip 'FIXME ->get on incr/decr value uses deserialiser', 1;
	$cache->get('ruuy', sub { is -1, undef, 'decr is successful in async mode'; Mojo::IOLoop->stop; });
	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}
for (0..3) {
	$cache->backend->{nodes}->[$_]->get('ruuy', sub { is shift, -1, "node $_ incremented correctly"; Mojo::IOLoop->stop; });
	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

# Delete (asynchronous)
$cache->del('ruux', sub { ok 1, 'callback is called on del in async mode'; Mojo::IOLoop->stop });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
for (0..3) {
	$cache->backend->{nodes}->[$_]->get('ruux', sub { is shift, undef, "node $_ deleted correctly"; Mojo::IOLoop->stop; });
	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}


done_testing(77);
