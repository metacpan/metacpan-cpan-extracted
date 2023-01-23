use 5.010001;
use strict;
use warnings;

package Story::Interact::Character;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001005';

use Moo;
use Types::Common -types;
use namespace::clean;

use overload (
	q[bool]  => sub { 1 },
	q[""]    => sub { shift->name },
	fallback => 1,
);

has 'name' => (
	is        => 'ro',
	isa       => NonEmptyStr,
	required  => 1,
);

has 'location' => (
	is        => 'rwp',
	isa       => Str | Undef,
);

has [ qw( meta knows carries achieved ) ] => (
	is        => 'ro',
	isa       => HashRef,
	builder   => sub { {} },
);

sub TO_JSON {
	+{ %{ +shift } };
}

1;
