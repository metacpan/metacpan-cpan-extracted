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

$cache->backend->support_sync(1);
is $cache->get('foo'), undef, 'unset key returns undef in sync mode';
$cache->set('foo' => 'BAR');
is $cache->get('foo'), 'BAR', 'set key returns correct value in sync mode';
is $cache->raw->get('foo'), '10R', 'set key returns correct value in sync mode';

done_testing(8);
