package Physics::Balls::World;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Physics::Balls::Engine;

our $VERSION = '0.01';

has L => (
	is => 'ro',
	isa => Num
);

has W => (
	is => 'ro',
	isa => Num
);

has R => (
	is => 'ro',
	isa => Num
);

has g => (
	is => 'ro',
	isa => Num,
	default => 9.81
);

has vmax => (
	is => 'ro',
	isa => Num,
	default => 8
);

has mu => (
	is => 'ro',
	isa => HashRef,
	default => { s => 0.2, r => 0.02, sp => 0.044 }
);

has e => (
	is => 'ro',
	isa => HashRef,
	default => { bb => 0.95, c => 0.8, cf => 0.2, rc => 0.7 }
);

has walls => (
	is => 'ro',
	isa => ArrayRef
);

has noses => (
	is => 'ro',
	isa => ArrayRef
);

has gates => (
	is => 'ro',
	isa => ArrayRef
);

has engine => (
	is => 'ro',
	lazy => 1,
	builder => 1
);

sub BUILD {
	my ($self) = @_;
	for my $f (qw/L W R/) {
		die "Physics::Balls::World: $f must be positive" unless defined $self->$f && $self->$f > 0;
	}
	for my $f (qw/walls noses gates/) {
		die "Physics::Balls::World: $f must be an array of arrays" unless ref $self->$f eq 'ARRAY';
	}
	return $self;
}

sub from_table {
	my ($class, $table, %constants) = @_;
	return $class->new(
		L => $table->L, W => $table->W, R => $table->R,
		walls => $table->walls, noses => $table->noses, gates => $table->gates,
		%constants,
	);
}

sub description {
	my ($self) = @_;
	return {
		L => $self->L, W => $self->W, R => $self->R, g => $self->g, vmax => $self->vmax,
		mu => $self->mu, e => $self->e,
		walls => $self->walls, noses => $self->noses, gates => $self->gates,
	};
}

sub _build_engine {
	my ($self) = @_;
	return Physics::Balls::Engine->new(%{ $self->description });
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::World - a surface, its walls, noses and gates, and the constants

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $world = Physics::Balls::World->from_table($table,
        mu => { s => 0.2, r => 0.015, sp => 0.044 },
        e  => { bb => 0.95, c => 0.8, cf => 0.2, rc => 0.7 },
        vmax => 8,
    );

    # or straight from geometry you built yourself, in metres
    my $world = Physics::Balls::World->new(L => 2.54, W => 1.27, R => 0.028575,
        walls => \@walls, noses => \@noses, gates => \@gates);

=head1 DESCRIPTION

Everything the engine needs to know before a strike. A world is built once
and shared between shots; the C engine behind it is created on the first
strike and freed with the world.

=head1 ATTRIBUTES

=head2 L

=head2 W

=head2 R

The playing area and the ball radius, metres.

=head2 g

Gravity, default 9.81.

=head2 vmax

The speed of a full-power strike, metres per second, default 8.

=head2 mu

C<s> sliding, C<r> rolling and C<sp> spinning friction, defaults 0.2, 0.02
and 0.044.

=head2 e

C<bb> ball-ball restitution, C<c> cushion restitution, C<cf> cushion friction
and C<rc> the share of a ball's roll a cushion keeps, defaults 0.95, 0.8, 0.2
and 0.7.

=head2 walls

=head2 noses

=head2 gates

As L<Physics::Balls::Table> returns them.

=head2 engine

The L<Physics::Balls::Engine>, built lazily.

=head1 METHODS

=head2 from_table

    my $world = Physics::Balls::World->from_table($table, %constants);

=head2 description

The hash the engine is built from.

=cut
