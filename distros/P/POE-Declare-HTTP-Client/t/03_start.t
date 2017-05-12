#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use Test::NoWarnings;
use Test::POE::Stopping;
use POE::Declare::HTTP::Client;
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
my @response = undef;
my $client   = POE::Declare::HTTP::Client->new(
	ResponseEvent => sub {
		die "This should never fire";
	},
	ShutdownEvent => sub {
		order( 3, 'Got client shutdown' );
	},
);
isa_ok( $client, 'POE::Declare::HTTP::Client' );






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
			$_[KERNEL]->delay_set( timeout  => 3 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );
			ok( ! $client->spawned, 'Client is not running' );
			ok( $client->start, '->start ok' );
		},

		shutdown => sub {
			order( 2, 'Fired main::shutdown' );
			ok( $client->spawned, 'Client is running' );
			ok( $client->stop, '->stop ok' );
		},

		timeout => sub {
			ok( ! $client->spawned, 'Client is stopped' );
			order( 4, 'Fired main::timeout' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;
