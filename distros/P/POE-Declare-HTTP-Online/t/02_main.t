#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	# $^W = 1;
}

use Test::More tests => 10;
# use Test::NoWarnings;
use Test::POE::Stopping;
use POE::Declare::HTTP::Online;
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}





######################################################################
# Test Object Generation

# Create the client
my $online = undef;
my $client = POE::Declare::HTTP::Online->new(
	Timeout      => 10,
	OnlineEvent  => sub {
		$online = 'online';
		order( 2, 'Got ONLINE reponse' );
	},
	OfflineEvent => sub {
		$online = 'offline';
		order( 2, 'Got OFFLINE reponse' );
	},
	ErrorEvent   => sub {
		$online = 'error';
		order( 2, 'Got ERROR response' );
	},
);
isa_ok( $client, 'POE::Declare::HTTP::Online' );






######################################################################
# Test Execution

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );

			# Start the timeout
			$_[KERNEL]->delay_set( start   => 1  );
			$_[KERNEL]->delay_set( timeout => 12 );
		},

		start => sub {
			order( 1, 'Fired main::startup' );
			ok( ! $client->spawned, 'Client is not running' );
			ok( $client->run, '->start ok' );
			ok( $client->spawned, 'Client is running' );
		},

		timeout => sub {
			ok( ! $client->spawned, 'Client is stopped' );
			order( 3, 'Fired main::timeout' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;

