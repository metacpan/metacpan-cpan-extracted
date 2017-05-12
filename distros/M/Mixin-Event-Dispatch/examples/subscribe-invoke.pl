#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:hireswallclock cmpthese);
use Mixin::Event::Dispatch::Bus;

my $obj = Mixin::Event::Dispatch::Bus->new;
$obj->subscribe_to_event(
	subscribe => sub {
		my ($ev, @param) = @_;
		print "Had 'subscribe' event with parameters: @param\n";
	},
);
$obj->invoke_event(
	subscribe => qw(one two three)
) for 1..10;
