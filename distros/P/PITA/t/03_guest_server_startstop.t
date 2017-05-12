#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use Test::POE::Stopping;
use File::Spec::Functions ':ALL';
use PITA::Guest::Server ();
use POE;

my $HOSTNAME = '127.0.0.1';
my $PORT     = 12345;

my $fail = catfile( qw{ t mock fail.pl } );
ok( -f $fail, "Found $fail" );

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my $server = PITA::Guest::Server->new(
	Hostname      => $HOSTNAME,
	Port          => $PORT,
	Mirrors       => { '/cpan/' => catdir('t', 'minicpan') },
	Program       => [ 'perl', $fail, "http://$HOSTNAME:$PORT/" ],
	StartupEvent  => [ test => 'started'  ],
	ShutdownEvent => [ test => 'shutdown' ],
);
isa_ok( $server, 'PITA::Guest::Server' );

# Set up the test session
POE::Session->create(
	inline_states => {
		_start => sub {
			order( 0, 'Fired main::_start' );
			$_[KERNEL]->alias_set('test');
			$_[KERNEL]->delay_set( timeout => 5 );
			$_[KERNEL]->yield('startup');
		},

		startup => sub {
			order( 1, 'Fired main::startup' );

			# Start the server
			ok( $server->start, '->start ok' );
		},

		started => sub {
			die "Server should not have started";
		},

		shutdown => sub {
			order( 2, 'Server ShutdownEvent' );
			is( $_[ARG1], 0, 'pinged is 0' );
			is( $server->pinged, 0, '->pinged is 0' );
			is_deeply( $_[ARG2], [ ], 'mirrored is [ ]' );
			is_deeply( $server->mirrored, [ ], '->mirrored is [ ]' );
			is_deeply( $_[ARG3], [ ], 'uploaded is [ ]' );
			is_deeply( $server->uploaded, [ ], '->uploaded is [ ]' );
			$_[KERNEL]->alias_remove('test');
			$_[KERNEL]->alarm_remove_all;
			$_[KERNEL]->yield('done');
		},

		done => sub {
			order( 3, 'main::done' );
			poe_stopping();
		},

		timeout => sub {
			poe_stopping();
		},
	},
);

$server->run
