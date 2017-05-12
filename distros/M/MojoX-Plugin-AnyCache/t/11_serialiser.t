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

package FakeSerialiser;
	use Mojo::Base 'MojoX::Plugin::AnyCache::Serialiser';
	sub deserialise {
	    my ($self, $data, $flags) = @_;
	    $data =~ tr/0-9/A-J/ if $data;
	    return $data;
	}
	sub serialise {
	    my ($self, $data) = @_;
	    $data =~ tr/A-J/0-9/ if $data;
	    return $data;
	}

package main;

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
my $cache = new_ok $class;

$cache->register(FakeApp->new, { backend => 'FakeBackend', serialiser => 'FakeSerialiser' });
isa_ok $cache->backend, 'FakeBackend';
can_ok $cache->backend, 'get';
can_ok $cache->backend, 'set';

$cache->backend->support_sync(0);
$cache->backend->support_async(0);

dies_ok { $cache->get('foo') } 'dies in sync mode without backend support';
like $@, qr/^Backend FakeBackend doesn't support synchronous requests/, 'correct error message in sync mode';
dies_ok { $cache->get('foo', sub {}) } 'dies in async mode without backend support';
like $@, qr/^Backend FakeBackend doesn't support asynchronous requests/, 'correct error message in async mode';

$cache->backend->support_sync(1);
is $cache->get('foo'), undef, 'unset key returns undef in sync mode';
$cache->set('foo' => 'BAR');
is $cache->get('foo'), 'BAR', 'set key returns correct value in sync mode';

is $cache->backend->get("foo"), '10R', 'serialised data is stored';

$cache->set('ruux' => 'BAR', 5);
is $cache->ttl('ruux'), 5, 'ttl not affected by serialiser';
is $cache->backend->get('ruux'), '10R', 'serialised data is stored with ttl';

$cache->backend->support_async(1);
$cache->get('qux', sub { is shift, undef, 'unset key returns undef in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->set('qux' => 'BAR', sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('qux', sub { is shift, 'BAR', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

is $cache->backend->get("qux"), '10R', 'serialised data is stored';

$cache->set('tuux' => 'BAR', 5, sub { ok(1, 'callback is called on set in async mode'); Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->ttl('tuux', sub { is shift, 5, 'set key with ttl returns correct ttl in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
$cache->get('tuux', sub { is shift, 'BAR', 'set key returns correct value in async mode'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
is $cache->backend->get("tuux"), '10R', 'serialised data is stored';

$cache->incr('quux', 1);
is $cache->backend->get('quux'), 1, 'serialiser not used for incr';
$cache->decr('quux', 1);
is $cache->backend->get('quux'), 0, 'serialiser not used for decr';

SKIP: {
	# Can't think of a sensible way to fix this...
	skip 'FIXME ->get on incr/decr value uses deserialiser', 1;
	is $cache->get('quux'), 1, 'serialiser not used for numeric value';	
}

done_testing(25);
