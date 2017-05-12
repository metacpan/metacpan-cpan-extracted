#!/usr/bin/env perl

use v5.14;

package Person {
	use Moose;
	use Types::Standard qw( Str Int );
	
	use overload (
		q[""]    => sub { $_[0]->name },
		q[eq]    => sub { $_[0]->equals($_[1]) },
		q[==]    => sub { $_[0]->equals($_[1]) },
		fallback => 1,
	);
	
	has name    => (
		is          => 'ro',
		isa         => Str,
		required    => 1,
	);
	
	has id      => (
		is          => 'ro',
		isa         => Int,
		required    => 1,
	);
	
	sub equals {
		my ($self, $other) = @_;
		return $self->id == $other->id;
	}
}

package Band {
	use Moose;
	use Types::Standard qw( Str InstanceOf );
	use Types::Set qw( Set );
	
	has name    => (
		is          => 'ro',
		isa         => Str,
		required    => 1,
	);
	
	has members => (
		is          => 'ro',
		isa         => Set[ InstanceOf['Person'] ],
		coerce      => 1,
		default     => sub { +[] },
		handles     => {
			add_member     => 'insert',
			has_member     => 'contains',
			member_count   => 'size',
		}
	);
}

my $beatles = 'Band'->new(
	name    => 'The Beatles',
	members => [
		'Person'->new(name => 'John Lennon',     id => 301),
		'Person'->new(name => 'Paul McCartney',  id => 302),
		'Person'->new(name => 'George Harrison', id => 303),
		'Person'->new(name => 'Ringo Starr',     id => 304),
	],
);

# A duplicate!
$beatles->add_member(
	'Person'->new(name => 'Richard Starkey', id => 304),
);

say for @{ $beatles->members };
