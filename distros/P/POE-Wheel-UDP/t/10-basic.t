#!/usr/bin/perl

use Test::More tests => 100;

use POE;
use POE::Wheel::UDP;
use POE::Filter::Stream;

POE::Session->create(
	package_states => [
		main => [ qw(_start wheel2_in sendone cleanup) ],
	],
);

sub _start {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	my $wheel1 = POE::Wheel::UDP->new(
		LocalAddr => '127.0.0.1',
		LocalPort => '2456',
		PeerAddr => '127.0.0.1',
		PeerPort => '2457',
		Filter => POE::Filter::Stream->new(),
	);

	my $wheel2 = POE::Wheel::UDP->new(
		LocalAddr => '127.0.0.1',
		LocalPort => '2457',
		PeerAddr => '127.0.0.1',
		PeerPort => '2456',
		InputEvent => 'wheel2_in',
		Filter => POE::Filter::Stream->new(),
	);

	$heap->{wheel1} = $wheel1;
	$heap->{wheel2} = $wheel2;

	$kernel->yield( 'sendone', 1 );

	return;
}

sub sendone {
	my ($kernel, $heap, $num) = @_[KERNEL,HEAP,ARG0];
	if ($num > 100) {
		$kernel->delay( cleanup => 1 );
		return;
	}

	my $thing = { payload => [ $num ] };
	$heap->{flags}->{$num}++;
	$heap->{wheel1}->put( $thing );
	$num++;
	$kernel->yield( 'sendone', $num );
}

sub wheel2_in {
	my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
	my $payload = $input->{payload};
	my $flags = $heap->{flags};

	foreach my $flag (@$payload) {
		if( exists( $flags->{$flag} )) {
			delete $flags->{$flag};
			pass( "Got $flag" );
		}
		else {
			fail( "$flag arrived without being keyed" );
		}
	}
	
	if (keys %$flags == 0) {
		$kernel->delay( cleanup => 0 );
	}
}

sub cleanup {
	my $heap = $_[HEAP];
	my $flags = $heap->{flags};
	my $wheel1 = delete $heap->{wheel1};
	my $wheel2 = delete $heap->{wheel2};

	foreach my $key (keys %$flags) {
		fail( "$key didn't arrive, ever" );
	}
}

POE::Kernel->run();
