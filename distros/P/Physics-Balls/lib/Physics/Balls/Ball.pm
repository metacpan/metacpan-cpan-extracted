package Physics::Balls::Ball;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.07';

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

has kind => (
	is => 'ro',
	isa => Int,
	default => 0
);

has vx => (
	is => 'ro',
	isa => Int,
	default => 0
);

has vy => (
	is => 'ro',
	isa => Int,
	default => 0
);

sub moving_row {
	my ($self) = @_;
	return [ $self->id, $self->x, $self->y, $self->kind, $self->vx, $self->vy ];
}

sub from_metres {
	my ($class, $id, $x, $y, $kind) = @_;
	return $class->new(id => $id, x => int($x * 1e5 + ($x < 0 ? -0.5 : 0.5)), y => int($y * 1e5 + ($y < 0 ? -0.5 : 0.5)), kind => $kind || 0);
}

sub metres {
	my ($self) = @_;
	return ($self->x * 1e-5, $self->y * 1e-5);
}

sub row {
	my ($self) = @_;
	return $self->kind ? [ $self->id, $self->x, $self->y, $self->kind ] : [ $self->id, $self->x, $self->y ];
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Ball - one ball's place in a layout

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    my $ball = Physics::Balls::Ball->new(id => 3, x => 190500, y => 63500);
    my ($x, $y) = $ball->metres;
    my $row = $ball->row;     # [3, 190500, 63500], what a layout holds

    my $bowl = Physics::Balls::Ball->new(id => 4, x => 0, y => 200000, kind => 1);
    $bowl->row;               # [4, 0, 200000, 1]: a ball of the world's kind 1

=head1 DESCRIPTION

A layout is a list of C<[id, x, y]> rows in hundredths of a millimetre, or
C<[id, x, y, kind]> when the ball is of a kind the world declares; this is
the row as an object for a caller that wants one. The engine takes rows or
these interchangeably.

=head1 METHODS

=head2 id

=head2 x

=head2 y

Integers, hundredths of a millimetre.

=head2 kind

An integer index into the world's kinds, default 0. A world that declares no
kinds has only kind 0, a ball that never curves.

=head2 from_metres

    my $ball = Physics::Balls::Ball->from_metres(3, 1.905, 0.635);
    my $bowl = Physics::Balls::Ball->from_metres(4, 0, 2, 1);

Rounds to the nearest hundredth.

=head2 metres

The position as two doubles.

=head2 row

The C<[id, x, y]> row, with the kind as a fourth element when it is not 0, so
a layout of ordinary balls is spelled as it always was.

=head2 vx

=head2 vy

Since 0.07: a starting velocity in hundredths of a millimetre a second, for an
advance; default 0.

=head2 moving_row

The C<[id, x, y, kind, vx, vy]> row an advance takes.

=cut
