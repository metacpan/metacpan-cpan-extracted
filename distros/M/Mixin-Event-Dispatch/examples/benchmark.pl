#!/usr/bin/env perl
use strict;
use warnings;
package main;
use Benchmark qw(:hireswallclock cmpthese);
use Mixin::Event::Dispatch::Bus;
use Mixin::Event::Dispatch::Event;

my $obj = Mixin::Event::Dispatch::Bus->new;
$obj->add_handler_for_event(
	invoke => sub {
		my ($ev) = @_;
	},
);
$obj->add_handler_for_event(
	two => sub {
		my ($ev) = @_;
	},
) for 1..2;
$obj->subscribe_to_event(
	subscribe => sub {
		my ($ev) = @_;
	},
);
cmpthese -3 => {
	subscribe => sub {
		$obj->subscribe_to_event(
			subscriber => sub { },
		);
	},
	add_handler => sub {
		$obj->add_handler_for_event(
			add_handler => sub { },
		);
	},
	invoke => sub {
		$obj->invoke_event('invoke')
	},
	invoke_two => sub {
		$obj->invoke_event('two')
	},
	invoke_missing => sub {
		$obj->invoke_event('missing')
	},
	invoke_subscription => sub {
		$obj->invoke_event('subscribe')
	},
	instantiate_event => sub {
		Mixin::Event::Dispatch::Event->new(
			name => 'some_event',
			instance => $obj,
			handlers => [ sub {}, sub {} ],
		);
	},
	bless_event => sub {
		bless {
			name => 'some_event',
			instance => $obj,
			handlers => [ sub {}, sub {} ],
		}, 'Mixin::Event::Dispatch::Event';
	}
};

warn "done\n";

