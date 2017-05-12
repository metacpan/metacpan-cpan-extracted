#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'POE::Component::ResourcePool::Resource::TokenBucket';

use POE::Component::ResourcePool;

use Time::HiRes qw(time);
use POE;

my $got = 0;

my $total = 50;
my $rate = 200;

{

	my $tb = POE::Component::ResourcePool::Resource::TokenBucket->new( rate => $rate, burst => 1 );

	my $pool = POE::Component::ResourcePool->new(
		resources => {
			tb => $tb,
		},
	);

	foreach my $thing ( 1 .. $total ) {
		POE::Session->create(
			inline_states => {
				_start => sub {
					$pool->request(
						params => { tb => 1 },
						event  => "got",
					);
				},
				got => sub { $got++ },
			},
		);
	}
}

my $t = time;

$poe_kernel->run;

is( $got, $total, "$total items dispatched" );

cmp_ok( time - $t, '>=', $total/$rate, "throttled" );

