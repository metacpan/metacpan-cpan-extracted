#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $class = "MojoX::Plugin::ManyCache";
use_ok $class;
my $cache = new_ok $class;

package FakeApp;

	use Mojo::Base -base;
	use Test::More;
	sub helper {
		my ($self, $helper, $sub) = @_;
		ok(1, 'helper is called');
		is($helper, 'cache', 'cache helper is registered');
		isa_ok($sub->(undef, 'cache_one'), 'MojoX::Plugin::AnyCache', 'cache object is returned by helper sub');
	}

package main;

lives_ok { $cache->register( FakeApp->new, 
                             names  => ['cache_one', 'cache_two'], 
                             config => { cache_one => {}, cache_two => {}  }
                            ) 
          } 'register call successful';

#isa_ok $cache->cache('cache_one'),  'FakeApp', 'application is stored correctly';
#is_deeply $cache->config, { foo => 'bar' }, 'plugin config is stored correctly';

# TODO More tests

done_testing(6);
