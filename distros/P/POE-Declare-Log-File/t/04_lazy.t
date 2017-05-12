#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;
use Test::POE::Stopping;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use POE;
use POE::Declare::Log::File ();

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}

# Identify the test files
my $file = catfile( 't', '04_lazy.1' );
clear($file);
ok( ! -f $file, "Test file $file does not exist" );





######################################################################
# Test Object

my $log = POE::Declare::Log::File->new(
	Filename => $file,
	Lazy     => 1,
);
isa_ok( $log, 'POE::Declare::Log::File' );
ok( ! -f $file, 'Log file object with Lazy does not open file' );





######################################################################
# Test Session

# Set up the test session
POE::Session->create(
	inline_states => {

		_start => sub {
			# Start the server
			order( 0, 'Fired main::_start' );

			$_[KERNEL]->delay_set( startup => 0.2 );
			$_[KERNEL]->delay_set( running => 0.4 );
			$_[KERNEL]->delay_set( flushed => 0.6 );
			$_[KERNEL]->delay_set( stopped => 0.8 );
			$_[KERNEL]->delay_set( timeout => 1.0 );
		},

		startup => sub {
			order( 1, 'Fired main::startup' );

			# Start the log stream
			ok( ! exists $log->{buffer}, 'Buffer does not exist' );
			is( $log->{state}, 'STOP', 'STOP' );
			ok( $log->start, '->start ok' );
		},

		running => sub {
			order( 2, 'Fired main::running' );

			# Are we started?
			is( $log->{state}, 'LAZY', 'LAZY' );

			# Send a message
			ok( $log->print("Message"), '->print ok' );
			is( $log->{buffer}, "Message\n" );
		},

		flushed => sub {
			order( 3, 'Fired main::flushed' );

			# Are we back to idle again
			is( $log->{state}, 'IDLE', 'IDLE' );
			ok( exists $log->{buffer}, 'Buffer exists' );
			ok( ! defined $log->{buffer}, 'Buffer is empty' );

			# Stop the service
			ok( $log->stop, '->stop ok' );
		},

		stopped => sub {
			order( 4, 'Fired main::stopped' );
			is( $log->{state}, 'STOP', 'STOP' );
			ok( ! exists $log->{buffer}, 'Buffer does not exist' );
		},

		timeout => sub {
			order( 5, 'Fired main::timeout' );
			poe_stopping();
		},
	},
);

POE::Kernel->run;

# With the event sequence completed, the file should exist
ok( -f $file, "Created file $file" );
my $size = (stat($file))[7];
ok(
	($size >= 7 and $size <= 8),
	'File is the expected size',
);
