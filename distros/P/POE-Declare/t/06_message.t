#!/usr/bin/perl

# Tests for messages

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 19;
use Test::NoWarnings;
use POE;
use Test::POE::Stopping;

#BEGIN {
	#$POE::Declare::Meta::DEBUG = 1;
#}

# Test event firing order
my $order = 0;
sub order {
	my $position = shift;
	my $message  = shift;
	is( ++$order, $position, "$message ($position)" );
}





#####################################################################
# Generate the test class

SCOPE: {
	package Test1;

	use Test::More;
	use POE::Declare;

	declare EventOne   => 'Message';
	declare EventTwo   => 'Message';
	declare EventThree => 'Message';

	*order = *main::order;

	sub _start : Event {
		order(1, 'Test1._start');
		$_[0]->SUPER::_start(@_[1..$#_]);
		$_[SELF]->post('startup');
	}

	sub startup : Event {
		# Fire the message
		order(2, 'Test1.startup');
		$_[SELF]->EventOne('blah');
	}

	sub foo : Event {
		order(3, 'Test1.foo');
		is( $_[ARG0], 'Test1.1', 'Callback param ok' );
		is( $_[ARG1], 'blah', 'Callback param ok' );
		$_[SELF]->EventTwo('arg');
	}

	sub shutdown : Event {
		order(5, 'Test1.shutdown');
		$_[SELF]->finish;
		$_[SELF]->EventThree('done');
	}

	compile;
}





#####################################################################
# Tests

# Create the test session
my $foo = Test1->new(
	EventOne   => [ 'Test1.1', 'foo' ],
	EventTwo   => \&callback,
	EventThree => \&done,
);
isa_ok( $foo, 'Test1' );
is( ref($foo->{EventOne}), 'CODE', 'EventOne is a CODE reference' );
is( ref($foo->{EventTwo}), 'CODE', 'EventTwo is a CODE reference' );
is( ref($foo->{EventThree}), 'CODE', 'EventThree is a CODE reference' );
ok( $foo->spawn, '->spawn ok' );

sub callback {
	order(4, 'eventone');
	is( $_[0], 'Test1.1', 'First callback param is the alias' );
	is( $_[1], 'arg', 'Second callback param is the argument' );
	$foo->post('shutdown');
}

sub done {
	order(6, 'done');
	is( $_[0], 'Test1.1', 'First callback param is the alias'  );
	is( $_[1], 'done', 'Second callback param is the argument' );
	poe_stopping();
}

# Start the tests
POE::Kernel->run;
