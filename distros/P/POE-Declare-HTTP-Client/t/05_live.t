#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
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

# This should redirect to http://www.google.com/
my $URL = 'http://google.com/';





######################################################################
# Test Object Generation

# Create the client
my @response = undef;
my $client   = POE::Declare::HTTP::Client->new(
	MaxRedirect   => 1,
	ResponseEvent => sub {
		order( 3, 'Got response' );
		my $response = $_[1];
		isa_ok( $response, 'HTTP::Response' );
		while ( $response->previous ) {
			$response = $response->previous;
		}
		isa_ok( $response, 'HTTP::Response' );

		my $request = $response->request;
		isa_ok( $request, 'HTTP::Request' );
		is( $request->uri->as_string, $URL );
	},
	ShutdownEvent => sub {
		order( 5, 'Got client shutdown' );
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
			$_[KERNEL]->delay_set( request  => 2 );
			$_[KERNEL]->delay_set( shutdown => 5 );
			$_[KERNEL]->delay_set( timeout  => 7 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );
			ok( $client->start, '->start ok' );
		},

		request => sub {
			order( 2, 'Fired main::request' );
			ok( $client->GET($URL), '->GET ok' );
		},

		shutdown => sub {
			order( 4, 'Fired main::shutdown' );
			ok( $client->stop, '->stop ok' );
		},

		timeout => sub {
			order( 6, 'Fired main::timeout' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;
