#! /usr/bin/env perl
our $rand;
BEGIN {
	# Install a global replacement for rand() that allows later tests to
	# override it on demand.
	*CORE::GLOBAL::rand= sub {
		defined $rand? $rand * ( @_? $_[0] : 1 ) : CORE::rand(@_);
	}
}
use Test2::V0 -target => 'Mock::Data::Set';

subtest constructors => \&test_constructors;
subtest weighted_distribution => \&test_weighted_distribution;

sub test_constructors {
	is(
		$CLASS->new(['a']),
		object {
			call items => [ 'a' ];
			call generate => 'a';
			call sub { shift->compile->() } => 'a';
		},
		'uniform distribution of one single item'
	);

	is(
		$CLASS->new(['a', 'b', 'c']),
		object {
			call items => [ 'a', 'b', 'c' ];
			call generate => in_set( 'a', 'b', 'c' );
		},
		'uniform distribution, several items'
	);

	is(
		$CLASS->new_weighted( a => 2, b => 3 ),
		object {
			call items => [ 'a', 'b' ];
			call weights => [ 2, 3 ];
			call generate => in_set( 'a', 'b' );
		},
		'weighted distribution'
	);
}

sub test_weighted_distribution {
	# Call weighted selection 100 times with successive values of rand() to ensure correct distribution
	no warnings 'redefine';
	my $pct100= $CLASS->new_weighted(
		a => 10,
		b => 49,
		c => 01,
		d => 20,
		e => 20,
	);
	my %counts;
	for my $i (0..99) {
		local $rand= $i / 100;
		++$counts{ $pct100->generate() };
	}
	is(
		\%counts,
		{
			a => 10,
			b => 49,
			c => 01,
			d => 20,
			e => 20,
		}
	);
}

done_testing;
