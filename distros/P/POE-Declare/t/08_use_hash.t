#!/usr/bin/perl

# This is a copy of 03_simple.t but with compile time attribute declaration

use strict;
use warnings;
BEGIN {
	$|  = 1;
	# $POE::Declare::Meta::DEBUG = 1;
}

use Test::More tests => 57;
use Test::NoWarnings;
use Test::Exception;





#####################################################################
# Create the test class

SCOPE: {
	package Foo;

	use POE qw{ Session };
	use POE::Declare {
		bar => 'Internal',
		foo => 'Attribute',
		One => 'Param',
		Two => 'Param',
	};

	# Shut up a warning
	POE::Kernel->run;

	# Check that SELF is exported, and matches HEAP
	main::is( SELF, HEAP, 'SELF == HEAP' );

	sub findme : Event {
		my $self = $_[SELF];
		return $self;
	}

	$Foo::to = 0;
	sub to : Timeout(30) {
		my $self = $_[SELF];
		$Foo::to++;
	}

	1;
}





#####################################################################
# Tests

my $ID1 = ($POE::VERSION >= 1.310) ? 1 : 2;

SCOPE: {
	# There should be no meta-object for the Foo class initially
	is( POE::Declare::meta('Foo'), undef, 'meta(Foo) is undef' );

	# Compile the class
	SCOPE: {
		package Foo;
		Test::More::is(
			POE::Declare::compile,
			1,
			'compile(Foo) returns true',
		);
	}

	# Check the meta-object
	my $meta = POE::Declare::meta('Foo');
	isa_ok( $meta, 'POE::Declare::Meta' );
	is( $meta->compiled, 1, '->compiled is true' );
	is( $meta->name, 'Foo', '->name is ok' );
	my $meta2 = Foo->meta;
	isa_ok( $meta, 'POE::Declare::Meta' );
	is_deeply( $meta, $meta2, 'Foo->meta ok' );
	is( ref($meta->{attr}), 'HASH', '->{attr} is a hash' );
	isa_ok( $meta->{attr}->{foo},    'POE::Declare::Meta::Attribute' );
	isa_ok( $meta->{attr}->{bar},    'POE::Declare::Meta::Internal'  );
	isa_ok( $meta->{attr}->{findme}, 'POE::Declare::Meta::Event'     );
	isa_ok( $meta->{attr}->{to},     'POE::Declare::Meta::Timeout'   );
	is( $meta->{attr}->{foo}->name,    'foo',    'Attribute foo ->name ok'    );
	is( $meta->{attr}->{bar}->name,    'bar',    'Attribute bar ->name ok'    );
        is( $meta->{attr}->{findme}->name, 'findme', 'Attribute findme ->name ok' );
	is( $meta->{attr}->{to}->name,     'to',     'Attribute to ->name ok'     );

	# Create an object
	my $object = Foo->new( One => 'foo' );
	isa_ok( $object, 'Foo' );
	is( $object->One,   'foo',   '->foo created and returns correctly' );
	is( $object->Alias, 'Foo.1', 'Pregenerated ->Alias returns as expected' );

	# Test errors
	throws_ok(
		sub {
			Foo->new( foo => 'bar' );
		},
		qr/Unknown or unsupported Foo param\(s\) foo/,
		'Threw expected constructor error',
	);

	# Check the kernel method
	isa_ok( $object->kernel, 'POE::Kernel' );

	# Check the attr method
	isa_ok( $meta->attr('foo'),    'POE::Declare::Meta::Attribute' );
	isa_ok( $meta->attr('bar'),    'POE::Declare::Meta::Internal'  );
	isa_ok( $meta->attr('findme'), 'POE::Declare::Meta::Event'     );
	isa_ok( $meta->attr('to'),     'POE::Declare::Meta::Timeout'   );
	isa_ok( $meta->attr('One'),    'POE::Declare::Meta::Param'     );
	isa_ok( $meta->attr('Two'),    'POE::Declare::Meta::Param'     );
	is( $meta->attr('foo')->name,    'foo',    'Attribute foo ->name ok'    );
	is( $meta->attr('bar')->name,    'bar',    'Attribute bar ->name ok'    );
	is( $meta->attr('findme')->name, 'findme', 'Attribute findme ->name ok' );
	is( $meta->attr('to')->name,     'to',     'Attribute to ->name ok'     );
	is( $meta->attr('One')->name,    'One',    'Attribute One ->name ok'    );
	is( $meta->attr('Two')->name,    'Two',    'Attribute Two ->name ok'    );

	# Check for the base attributes
	isa_ok( $meta->attr('_start'),        'POE::Declare::Meta::Event' );
	isa_ok( $meta->attr('_stop'),         'POE::Declare::Meta::Event' );

	# Check the package_states method
	is_deeply(
		[ $meta->_package_states ],
		[ '_start', '_stop', 'findme', 'to' ],
		'->_package_states returns as expected',
	);

	# Check the params method
	is_deeply(
		[ $meta->_params ],
		[ 'Alias', 'One', 'Two' ],
		'->_params returns as expected',
	);

	# Check various spawning related methods
	is( $object->spawned, '', '->spawned is false' );
	is( $object->session_id, undef, '->session_id is undef' );
	is( $object->ID, undef, '->ID is undef' );
	is( $object->session, undef, '->session is undef' );
	$object->spawn;
	is( $object->spawned, 1,  '->spawned is true'  );
	is( $object->session_id, $ID1, '->session_id is true' );
	is( $object->ID, $ID1, '->ID is true and matches ->session_id' );
	isa_ok( $object->session, 'POE::Session', '->session is true' );

	# Check the behaviour of SELF in methods
	my $me = $object->call('findme');
	is_deeply( $me, $object, 'SELF works in methods' );
	$object->call('to');
	is( $Foo::to, 1, 'Timeout method called directly increments to' );

	# Check the postback method
	my $postback = $object->postback('findme');
	isa_ok( $postback, 'POE::Session::AnonEvent' );

	# Check the callback method
	my $callback = $object->callback('findme');
	isa_ok( $postback, 'POE::Session::AnonEvent' );

	# Check the lookback method
	my $lookback = $object->lookback('findme');
	is_deeply(
		$lookback,
		[ 'Foo.1', 'findme' ],
		'Created lookback ARRAY',
	);
}





#####################################################################
# Create a subclass

SCOPE: {
	package My::Foo;

	use vars qw{@ISA};
	BEGIN {
		@ISA = 'Foo';
	}

	use POE::Declare {
		baz     => 'Attribute',
		MyParam => 'Param',
	};

	compile;
}





#####################################################################
# Testing the subclass

SCOPE: {
	my $meta = POE::Declare::meta('My::Foo');
	isa_ok( $meta, 'POE::Declare::Meta' );
	is( $meta->name, 'My::Foo', '->name ok' );

	# Check the attr method
	isa_ok( $meta->attr('baz'), 'POE::Declare::Meta::Attribute' );
	isa_ok( $meta->attr('MyParam'), 'POE::Declare::Meta::Param' );
	isa_ok( $meta->attr('foo'), 'POE::Declare::Meta::Attribute' );
}
