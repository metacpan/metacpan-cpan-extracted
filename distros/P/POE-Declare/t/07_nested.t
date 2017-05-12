#!/usr/bin/perl

# Tests for messages

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 33;
use Test::NoWarnings;
use POE;
use Test::POE::Stopping;

BEGIN {
	no warnings;
	$POE::Debug::DEBUG = 1;
}

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( ++$order, $position, "$message ($position)" );
}





#####################################################################
# Generate the test classes

CLASS: {
	package Test1;

	use Test::More;
	use POE::Declare;

	*order = *main::order;

	declare Started => 'Message';
	declare Stopped => 'Message';
	declare child   => 'Internal';

	sub _start : Event {
		order(1, 'Test1._start');
		$_[0]->SUPER::_start(@_[1..$#_]);
		$_[SELF]->post('startup');
	}

	sub _stop : Event {
		order(14, 'Test1._stop');
		$_[0]->SUPER::_stop(@_[1..$#_]);
	}

	sub startup : Event {
		order(2, 'Test1.startup');
		my $test = 'foo';
		$_[SELF]->{child} = Test2->new(
			Started => $_[SELF]->postback('child_startup', 5),
			Stopped => $_[SELF]->callback('child_shutdown', 12),
			Echo1   => $_[SELF]->postback('message1', 10),
			Echo2   => $_[SELF]->callback('message2', 7),
			Echo3   => $_[SELF]->lookback('message3'),
			Echo4   => \&message4,
		);
		$_[SELF]->{child}->spawn;
		$_[SELF]->Started;
	}

	sub child_startup : Event {
		order(6, 'Test1.child_startup');
		is_deeply( $_[ARG0], [ 5 ], 'Test2.1 child_startup' );
		is_deeply( $_[ARG1], [ 'Test2.1' ], 'Test2.1 child_startup' );
		$_[SELF]->{child}->post('echo', 'abcdefg');
	}

	sub child_shutdown : Event {
		order(13, 'Test1.child_shutdown');
		is_deeply( $_[ARG0], [ 12 ], 'Test2.1 child_shutdown param ok' );
		is_deeply( $_[ARG1], [ 'Test2.1' ], 'Test2.1 child_shutdown alias ok' );
		$_[SELF]->finish;
		$_[SELF]->Stopped;
	}

	sub message1 : Event {
		order(11, 'Test1.message1');
		is_deeply( $_[ARG0], [ 10 ], 'Test2.1 message1' );
		is_deeply( $_[ARG1], [ 'Test2.1', 'abcdefg' ], '... and param ok' );

		# The postback should receive the event last
		$_[SELF]->{child}->call('shutdown');
	}

	sub message2 : Event {
		order(8, 'Test1.message2');
		is_deeply( $_[ARG0], [ 7 ], 'Test2.1 message2' );
		is_deeply( $_[ARG1], [ 'Test2.1', 'abcdefg' ], '... and param ok' );
	}

	sub message3 : Event {
		order(9, 'Test1.message3');
		is( $_[ARG0], 'Test2.1', 'Test2.1 message3' );
		is( $_[ARG1], 'abcdefg', '... and param ok' );
	}

	sub message4 {
		order(10, 'Test1::startup');
		is( $_[0], 'Test2.1', 'Test2.1 message4' );
		is( $_[1], 'abcdefg', '... and param ok' );		
	}

	compile;
}

CLASS: {
	package Test2;

	use Test::More;
	use POE::Declare;

	*order = *main::order;

	declare Started => 'Message';
	declare Stopped => 'Message';
	declare Echo1   => 'Message';
	declare Echo2   => 'Message';
	declare Echo3   => 'Message';
	declare Echo4   => 'Message';

	sub _start : Event {
		order(3, 'Test2._start');
		$_[0]->SUPER::_start(@_[1..$#_]);
		$_[SELF]->post('startup');
	}

	sub _stop : Event {
		order(15, 'Test2._stop');
		$_[0]->SUPER::_stop(@_[1..$#_]);
	}

	sub startup : Event {
		order(5, 'Test2.startup');
		# Nothing to do, just post the message
		$_[SELF]->Started;
	}

	sub echo : Event {
		order(7, 'Test2.echo');
		my $value = $_[ARG0];
		$_[SELF]->Echo1($value);
		$_[SELF]->Echo2($value);
		$_[SELF]->Echo3($value);
		$_[SELF]->Echo4($value);
		return;
	}

	sub shutdown : Event {
		order(12, 'Test2.shutdown');
		$_[SELF]->finish;
		$_[SELF]->Stopped;
		foreach ( $_[SELF]->meta->_params ) {
			delete $_[SELF]->{$_};
		}
	}

	compile;
}





#####################################################################
# Tests

# Start the test session
my $foo = Test1->new(
	Started => \&callback,
	Stopped => [ 'Test1.1', 'foo' ],
);
isa_ok( $foo, 'Test1' );
is( ref($foo->{Started}), 'CODE', 'Started is a CODE reference' );
is( ref($foo->{Stopped}), 'CODE', 'Stopped is a CODE reference' );
ok( $foo->spawn, '->spawn ok' );

sub callback {
	order(4, 'callback');
	is( $_[0], 'Test1.1', 'First callback param is the alias' );
}

sub done {
	order(13, 'done');
	is( $_[0], 'Test1.1', 'First callback param is the alias'  );
	is( $_[1], 'done', 'Second callback param is the argument' );
	poe_stopping();
}

# Start the tests
POE::Kernel->run;
