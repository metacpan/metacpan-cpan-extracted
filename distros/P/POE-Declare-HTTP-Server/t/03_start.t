#!/usr/bin/perl

# Simple start/stop operation without making any requests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Test::NoWarnings;
use Test::POE::Stopping;
use POE::Declare::HTTP::Server ();
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}





######################################################################
# Test Class Generation

# Create the server
my $server = POE::Declare::HTTP::Server->new(
	Hostname => '127.0.0.1',
	Port     => '8010',
	Handler  => sub {
		my $server   = shift;
		my $response = shift;

		$response->code( 200 );
		$response->header( 'Content-Type' => 'text/plain' );
		$response->content( 'Hello World!' );

		return 1;
	},

	StartupEvent => sub {
		order( 2, 'Fired StartupEvent message' );
	},

	ShutdownEvent => sub {
		order( 4, 'Fired ShutdownEvent' );
	},

);
isa_ok( $server, 'POE::Declare::HTTP::Server' );





######################################################################
# Test Execution

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );

			# Start the timeout
			$_[KERNEL]->delay_set( startup  => 1 );
			$_[KERNEL]->delay_set( shutdown => 2 );
			$_[KERNEL]->delay_set( timeotu  => 3 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );
			ok( ! $server->spawned, 'Server is not spawned' );
			ok( $server->start, '->start ok' );
		},

		shutdown => sub {
			order( 3, 'Fired main::shutdown' );
			ok( $server->spawned, 'Server is spawned' );
			ok( $server->stop, '->stop ok' );
		},

		timeout => sub {
			order( 5, 'Fired main::timeout' );
			ok( $server->stop, '->stop ok' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;
