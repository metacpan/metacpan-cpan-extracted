#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use Test::POE::Stopping;
use File::Spec::Functions ':ALL';
use PITA::Guest::Server ();
use POE;

my $HOSTNAME = '127.0.0.1';
my $PORT     = 12345;

my $test = catfile( qw{ t mock test.pl } );
ok( -f $test, "Found $test" );

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

my $server = PITA::Guest::Server->new(
	Hostname      => '127.0.0.1',
	Port          => 12345,
	Mirrors       => { '/cpan/' => catdir('t', 'minicpan') },
	Program       => [ 'perl', $test, "http://$HOSTNAME:$PORT/" ],
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
			$_[KERNEL]->delay_set( timeout => 20 );
			$_[KERNEL]->yield('startup');
		},

		startup => sub {
			order( 1, 'Fired main::startup' );

			# Start the server
			ok( $server->start, '->start ok' );
		},

		started => sub {
			order( 2, 'Server StartupEvent' );
		},

		shutdown => sub {
			order( 3, 'Server ShutdownEvent' );
			is( $_[ARG1], 1, 'pinged ok' );
			is_deeply(
				$_[ARG2],
				[
					[ '/cpan/', 'Config-Tiny-2.13.tar.gz', 200 ],
				],
				'mirrored is null',
			);
			is_deeply(
				$_[ARG3],
				[
					[
						'/response.xml',
						\"This is my response",
					],
				],
				'uploaded expected file',
			);
			$_[KERNEL]->alias_remove('test');
			$_[KERNEL]->alarm_remove_all;
			$_[KERNEL]->yield('done');
		},

		done => sub {
			order( 4, 'main::done' );
			poe_stopping();
		},

		timeout => sub {
			poe_stopping();
		},
	},
);

$server->run;
