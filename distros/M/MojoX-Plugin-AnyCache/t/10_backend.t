#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
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

$cache->register(FakeApp->new, { backend => 'FakeBackend' });
isa_ok $cache->backend, 'FakeBackend';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';
can_ok $cache->backend, 'incr';
can_ok $cache->backend, 'decr';
can_ok $cache->backend, 'del';

is $cache->backend->support_sync, 1, 'default support_sync value retrieved';
is $cache->backend->support_async, 1, 'default support_sync value retrieved';

$cache->backend->support_sync(0);
$cache->backend->support_async(0);

is $cache->backend->support_sync, 0, 'new support_sync value retrieved';
is $cache->backend->support_async, 0, 'new support_sync value retrieved';

dies_ok { $cache->get('foo') } 'dies in sync mode without backend support';
like $@, qr/^Backend FakeBackend doesn't support synchronous requests/, 'correct error message in sync mode';
dies_ok { $cache->get('foo', sub {}) } 'dies in async mode without backend support';
like $@, qr/^Backend FakeBackend doesn't support asynchronous requests/, 'correct error message in async mode';

$cache->backend->support_sync(1);
is $cache->get('foo'), undef, 'unset key returns undef in sync mode';
$cache->set('foo' => 'bar');
is $cache->get('foo'), 'bar', 'set key returns correct value in sync mode';

$cache->set('ruux' => 1, 5);
is $cache->ttl('ruux'), 5, 'ttl returns correct value in sync mode';
is $cache->get('ruux'), 1, 'set with ttl returns correct value in sync mode';

is $cache->incr('bar', 1), 1, 'incr by 1 on unset value returns 1';
is $cache->incr('baz', 5), 5, 'incr by 5 on unset value returns 5';
is $cache->incr('bar', 2), 3, 'incr by 2 on 1 returns 3';
is $cache->incr('bar', 0), 3, 'incr by 0 on 3 returns 3';
is $cache->incr('bar', -1), 2, 'incr by -1 on 3 returns 2';

is $cache->decr('quux', 1), -1, 'decr by -1 on unset value returns -1';
is $cache->decr('quuy', 5), -5, 'decr by -5 on unset value returns -5';
is $cache->decr('quux', 2), -3, 'decr by -2 on -1 returns -3';
is $cache->decr('quux', 0), -3, 'decr by 0 on -3 returns -3';
is $cache->decr('quux', -1), -2, 'decr by -1 on -3 returns -2';

is $cache->get('quux'), -2, 'correct value returned by get';
$cache->del('quux');
is $cache->get('quux'), undef, 'value successfully deleted';

$cache->backend->support_async(1);
$cache->get('qux', sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set('qux' => 'bar', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('qux', sub { is shift, 'bar', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

$cache->set('ruux' => 'baz', 5, sub { ok(1, 'callback is called on set with ttl in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->ttl('ruux', sub { is shift, 5, 'set key with ttl returns correct ttl value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('ruux', sub { is shift, 'baz', 'set key with ttl returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing(38);
