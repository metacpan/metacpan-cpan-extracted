#!/usr/bin/perl

# Validate that _stop fires when expected

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 8;
# Disabled for now due to POE::Peek::API throwing warnings.
# use Test::NoWarnings;
use POE;
use Test::POE::Stopping;

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( $order++, $position, "$message ($position)" );
}





#####################################################################
# Generate the test class

SCOPE: {
	package Foo;

	use strict;
	use POE::Declare;
	use Test::More;

	*order = *main::order;

	declare bar => 'Internal';

	sub _start : Event {
		order( 0, 'Fired Foo::_start' );
		$_[0]->SUPER::_start(@_[1..$#_]);

		# Trigger a regular event
		$_[SELF]->post( say => 'Hello World!' );
	}

	sub say : Event {
		order( 2, 'Fired Foo::say' );
		$_[SELF]->finish;

		# Test that multiple calls to finish are benign
		# and will not throw an exception.
		$_[SELF]->finish;
	}

	sub _stop : Event {
		order( 3, 'Fired Foo::_stop' );
		$_[0]->SUPER::_stop(@_[1..$#_]);
	}

	compile;
}





#####################################################################
# Tests

# Start the test session
my $foo = new_ok( Foo => [] );
ok( $foo->spawn, '->spawn ok' );

# Start another session to intentionally
# prevent the kernel shutdown from firing
POE::Session->create(
	inline_states => {
		_start  => \&_start,
		_stop   => \&_stop,
		timeout => \&timeout,
	},
);

sub _start {
	order( 1, 'Fired main::_start' );
	$_[KERNEL]->delay_set( timeout => 0.5 );
}

sub _stop {
	order( 5, 'Fired main::_stop' );
}

sub timeout {
	order( 4, 'Fired main::timeout' );
}

POE::Kernel->run;
