#!/usr/bin/perl

# Tests for the HTTP server component of the support server only

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 37;
use Test::POE::Stopping;
use File::Spec::Functions ':ALL';
use PITA::Guest::Server::HTTP ();
use POE::Declare::HTTP::Client ();
use POE;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my $minicpan = rel2abs( catdir( 't', 'minicpan' ), );
ok( -d $minicpan, 'Found minicpan directory' );

# Preallocate variables so anonymous subs can refer to them
my $client    = undef;
my $server    = undef;
my $responses = 0;

# Create the test client
$client = POE::Declare::HTTP::Client->new(
	ResponseEvent => sub {
		if ( ++$responses == 1 ) {
			order( 4, "Client ResponseEvent $responses" );

			# Check the ping response
			isa_ok( $_[1], 'HTTP::Response' );
			ok( $_[1]->is_success, 'Response successful' );
			is( $_[1]->code, '200', 'Got a 200 response' );

			# Request a mirror file
			ok( $client->GET('http://127.0.0.1:12345/cpan/Config-Tiny-2.13.tar.gz'), '->GET ok' );

		} elsif ( $responses == 2 ) {
			order( 6, "Client ResponseEvent $responses" );

			# Check the get response
			isa_ok( $_[1], 'HTTP::Response' );
			ok( $_[1]->is_success, 'Response successful' );
			is( $_[1]->code, '200', 'Got a 200 response' );
			is(
				length($_[1]->content),
				16778,
				'->content length is correct',
			);

			# Upload the file
			ok(
				$client->PUT(
					'http://127.0.0.1:12345/file.txt',
					Content => 'This is content',
				),
				'->PUT ok',
			);

		} elsif ( $responses == 3 ) {
			order( 8, "Client ResponseEvent $responses" );

			# Check the get response
			isa_ok( $_[1], 'HTTP::Response' );
			ok( $_[1]->is_success, 'Response successful' );
			is( $_[1]->code, '204', 'Got a 204 response' );

			# We are finished sending all requests now
			ok( $client->stop, 'Client ->stop ok' );

		} else {
			die "Unexpected response";
		}
	},

	ShutdownEvent => sub {
		order( 9, "Client ShutdownEvent" );

		# Close down the server now
		ok( $server->stop, 'Server ->stop ok' );
	},
);
isa_ok( $client, 'POE::Declare::HTTP::Client' );

# Create the web server
$server = PITA::Guest::Server::HTTP->new(
	Hostname => '127.0.0.1',
	Port     => 12345,
	Mirrors  => {
		'/cpan/' => $minicpan,
	},

	StartupEvent => sub {
		order( 2, 'Server StartupEvent' );
		ok( $client->start, '->start ok' );
		ok( $client->GET('http://127.0.0.1:12345/'), '->GET ok' );
	},

	PingEvent => sub {
		order( 3, 'Server PingEvent' );
	},

	MirrorEvent => sub {
		order( 5, 'Server MirrorEvent' );
		is( $_[1], '/cpan/', 'Got route' );
		is( $_[2], 'Config-Tiny-2.13.tar.gz', 'Got file' );
	},

	UploadEvent => sub {
		order( 7, 'Server UploadEvent' );
	},

	ShutdownEvent => [
		test => 'shutdown',
	],
);
isa_ok( $server, 'PITA::Guest::Server::HTTP' );

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );

			# Register the session
			$_[KERNEL]->alias_set('test');

			# Start the timeout
			$_[KERNEL]->delay_set( startup => 1 );
			$_[KERNEL]->delay_set( timeout => 5 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );
			ok( !$client->spawned, 'Client not spawned' );
			ok( !$server->spawned, 'Server not spawned' );
			ok( $server->start, '->start ok' );
		},

		shutdown => sub {
			order( 10, 'Server ShutdownEvent' );

			# We're done now
			$_[KERNEL]->alias_remove('test');
			$_[KERNEL]->alarm_remove_all;
			$_[KERNEL]->yield('done');
		},

		done => sub {
			order( 11, 'Test session shutdown' );
			poe_stopping();
		},

		timeout => sub {
			ok( $server->stop, '->stop ok' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;
