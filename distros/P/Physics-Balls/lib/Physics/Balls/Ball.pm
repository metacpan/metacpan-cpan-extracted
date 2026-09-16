package Physics::Balls::Ball;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has id => (
	is => 'ro',
	isa => Int
);

has x => (
	is => 'ro',
	isa => Int
);

has y => (
	is => 'ro',
	isa => Int
);

sub from_metres {
	my ($class, $id, $x, $y) = @_;
	return $class->new(id => $id, x => int($x * 1e5 + ($x < 0 ? -0.5 : 0.5)), y => int($y * 1e5 + ($y < 0 ? -0.5 : 0.5)));
}

sub metres {
	my ($self) = @_;
	return ($self->x * 1e-5, $self->y * 1e-5);
}

sub row {
	my ($self) = @_;
	return [ $self->id, $self->x, $self->y ];
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Ball - one ball's place in a layout

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $ball = Physics::Balls::Ball->new(id => 3, x => 190500, y => 63500);
    my ($x, $y) = $ball->metres;
    my $row = $ball->row;     # [3, 190500, 63500], what a layout holds

=head1 DESCRIPTION

A layout is a list of C<[id, x, y]> rows in hundredths of a millimetre; this is
the row as an object for a caller that wants one. The engine takes rows or
these interchangeably.

=head1 METHODS

=head2 id

=head2 x

=head2 y

Integers, hundredths of a millimetre.

=head2 from_metres

    my $ball = Physics::Balls::Ball->from_metres(3, 1.905, 0.635);

Rounds to the nearest hundredth.

=head2 metres

The position as two doubles.

=head2 row

The C<[id, x, y]> row.

=cut
