#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 38;

use ok 'POE::Component::ResourcePool::Resource::Semaphore';
use ok 'POE::Component::ResourcePool::Resource::Collection';
use ok 'POE::Component::ResourcePool';

use Scalar::Util qw(weaken);

use POE;

for my $refc_alloc ( 0, 1 ) {
	my $max = 5;
	my $delay = 0.0001;
	my $total = 80;
	my $running = 0;
	my $max_running = 0;
	my $dispatched = 0;

	my $children = $total;

	POE::Session->create(
		inline_states => {
			_start => sub { $poe_kernel->yield("begin") },
			begin => sub {
				$_[HEAP]{alarm_id} = $poe_kernel->delay_set("exit", ( $total / $max ) );

				my $sem1 = POE::Component::ResourcePool::Resource::Semaphore->new( initial_value => $max * 8 );
				my $sem2 = POE::Component::ResourcePool::Resource::Semaphore->new( initial_value => $max );

				my $pool = POE::Component::ResourcePool->new(
					refcount_allocated => $refc_alloc,
					resources => { sem1 => $sem1, sem2 => $sem2},
				);

				foreach my $thing ( 1 .. $total ) {
					POE::Session->create(
						inline_states => {
							_start => sub {
								my ( $kernel, $heap, $session ) = @_[KERNEL, HEAP, SESSION];

								$kernel->yield("begin");
							},
							begin => sub {
								my ( $kernel, $heap, $session ) = @_[KERNEL, HEAP, SESSION];

								$heap->{request} = $pool->request(
									params => { sem1 => 1 + int(rand($max / 5)), sem2 => 1 + int(rand($max / 2)) },
									event  => "foo",
								);
							},
							foo => sub {
								$running++;
								$max_running = $running if $running > $max_running;
								$poe_kernel->delay_set("bar", $delay);
							},
							bar => sub {
								my ( $kernel, $heap, $session ) = @_[KERNEL, HEAP, SESSION];

								$dispatched++;

								$running--;

								if ( $refc_alloc ) {
									$heap->{request}->dismiss;
								}
							},
						},
					);
				}
			},
			_child => sub {
				if ( --$children == 0 ) {
					$poe_kernel->alarm_remove($_[HEAP]{alarm_id});
				}
			},
			exit => sub {
				fail("timed out");
				$poe_kernel->stop;
			}
		},
	);

	$poe_kernel->run;

	is( $dispatched, $total, "actually dispatched $total times" );

	cmp_ok( $max_running, '<=', $max, "never ran more than $max session simultaneously" );

	is( $running, 0, "counters are consistent" );
}

{
	my $pool = POE::Component::ResourcePool->new(
		resources => {
			thingys => POE::Component::ResourcePool::Resource::Collection->new(
				values => [qw(1 2 3)],
			)
		},
	);

	my ( $two, $four, $got_two, $got_four );

	POE::Session->create(
		inline_states => {
			_start => sub {
				$four = $_[HEAP]{r} = $pool->request( params => { thingys => 4 }, event => "got" );
			},
			got => sub {
				$got_four = $four->results;
			}
		},
	);

	POE::Session->create(
		inline_states => {
			_start => sub {
				$two = $_[HEAP]{r} = $pool->request( params => { thingys => 2 }, event => "got" );
			},
			got => sub {
				$got_two = $two->results;
				$two->dismiss;
			}
		},
	);

	POE::Session->create(
		inline_states => {
			_start => sub {
				$poe_kernel->delay_set( cancel => 0.01 );
			},
			cancel => sub {
				$_->dismiss for $pool->pending_requests;
			},
		},
	);

	is_deeply( [ sort $pool->pending_requests ], [ sort $two, $four ], "pending requests" );
	is_deeply( [ sort $pool->all_requests ], [ sort $two, $four ], "all_requests" );
	is_deeply( [ sort $pool->allocated_requests ], [ ], "allocated_requests" );

	$poe_kernel->run;

	is( $got_four, undef, "didn't get 4" );
	is_deeply( $got_two, { thingys => [ qw(1 2) ] }, "got 2" );
	ok( $two->fulfilled, "resource is fulfilled" );
	ok( !$two->canceled, "resource is not canceled" );
	ok( $four->canceled, "resource is canceled" );
}

{
	my $pool = POE::Component::ResourcePool->spawn(
		resources => {
			one => my $one = POE::Component::ResourcePool::Resource::Collection->new(
				values => [qw(1 2 3)],
			),
			two => my $two = POE::Component::ResourcePool::Resource::Collection->new(
				values => [qw(foo bar gorch)],
			),
			three => POE::Component::ResourcePool::Resource::Semaphore->new( initial_value => 2 ),
		},
	);

	POE::Session->create(
		inline_states => {
			_start => sub {
				my @requests = (
					$pool->request( params => { one => 1 }, event => "got" ),
					$pool->request( params => { two => 5 }, event => "got" ),
				);

				eval { $pool->request( params => { two => 1 } ) };
				my $e = $@;
				ok( $@, "got an error" );
				like( $@, qr/event/, "the right error" );
				like( $@, qr/callback/, "the right error" );
				like( $@, qr/basic\.t/, "it's a croak, not a die" );

				eval { $pool->request( params => { doesnt_exist => 3 }, event => "got" ) };
				$e = $@;
				ok( $@, "got an error" );
				like( $@, qr/no resource/, "the right error" );
				like( $@, qr/doesnt_exist/, "the right resource in the error" );
				like( $@, qr/basic\.t/, "it's a croak, not a die" );

				eval { $pool->request( params => { three => 3 }, event => "got" ) };
				$e = $@;
				ok( $@, "got an error" );
				like( $@, qr/rejected/, "the right error" );
				like( $@, qr/three/, "the right resource in the error" );
				like( $@, qr/basic\.t/, "it's a croak, not a die" );

				is_deeply( [ sort $pool->pending_requests ], [ sort @requests ], "pending requests" );

				is_deeply( [ $pool->pending_requests($one) ], [ $requests[0] ], "pending requests for resource" );

				is_deeply( [ $pool->allocated_requests ], [ ], "allocated requests" );

				$_[HEAP]{requests} = \@requests;
			},
			got => sub {
				my @requests = @{ $_[HEAP]{requests} };

				is_deeply( [ $pool->pending_requests ], [ $requests[1] ], "pending requests" );
				is_deeply( [ $pool->pending_requests($one) ], [ ], "pending requests for resource" );
				is_deeply( [ $pool->pending_requests($two) ], [ $requests[1] ], "pending requests for resource" );

				is_deeply( [ $pool->allocated_requests ], [ $requests[0] ], "allocated requests" );
				is_deeply( [ $pool->allocated_requests($one) ], [ $requests[0] ], "allocated requests" );
				is_deeply( [ $pool->allocated_requests($two) ], [ ], "allocated requests" );

				$requests[1]->dismiss;

				$pool->shutdown;
			}
		},
	);

	$poe_kernel->run;
}
