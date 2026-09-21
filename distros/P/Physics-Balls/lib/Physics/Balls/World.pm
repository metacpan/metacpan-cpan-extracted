package Physics::Balls::World;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Physics::Balls::Engine;

our $VERSION = '0.05';

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

has curve => (
	is => 'ro',
	isa => HashRef,
	default => { k => 0, vref => 1, vmin => 0.1, kmax => 1, p => 2, cap => 0.002, vfrac => 0.1 }
);

has kinds => (
	is => 'ro',
	isa => ArrayRef,
	default => []
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
	for my $f (qw/walls noses gates kinds/) {
		die "Physics::Balls::World: $f must be an array" unless ref $self->$f eq 'ARRAY';
	}
	for my $k (@{ $self->kinds }) {
		die "Physics::Balls::World: a kind is a hash" unless ref $k eq 'HASH';
		die "Physics::Balls::World: a kind's curve is a number" if defined $k->{curve} && $k->{curve} !~ /\A-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/;
		die "Physics::Balls::World: a kind's follow is a number from 0 to 1" if defined $k->{follow} && !($k->{follow} =~ /\A\d+(?:\.\d+)?\z/ && $k->{follow} <= 1);
		for my $f (qw/r m mu rs/) {
			die "Physics::Balls::World: a kind's $f is a positive number" if defined $k->{$f} && !($k->{$f} =~ /\A\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/ && $k->{$f} > 0);
		}
		die "Physics::Balls::World: a kind's vfall is a number of zero or more" if defined $k->{vfall} && $k->{vfall} !~ /\A\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/;
	}
	my $p = $self->curve->{p};
	die "Physics::Balls::World: curve p must be an integer from 0 to 4" if defined $p && ($p !~ /\A\d\z/ || $p > 4);
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

sub kind_count {
	my ($self) = @_;
	return scalar @{ $self->kinds };
}

sub kind_radius {
	my ($self, $k) = @_;
	my $kind = $self->kinds->[ $k || 0 ];
	return $kind && $kind->{r} ? $kind->{r} : $self->R;
}

sub kind_sweep {
	my ($self, $k) = @_;
	my $kind = $self->kinds->[ $k || 0 ];
	return $kind && $kind->{rs} ? $kind->{rs} : $self->kind_radius($k);
}

sub reach {
	my ($self, $a, $b) = @_;
	$a ||= 0; $b ||= 0;
	return $a == $b ? $self->kind_sweep($a) + $self->kind_sweep($b) : $self->kind_radius($a) + $self->kind_radius($b);
}

sub description {
	my ($self) = @_;
	return {
		L => $self->L, W => $self->W, R => $self->R, g => $self->g, vmax => $self->vmax,
		mu => $self->mu, e => $self->e,
		walls => $self->walls, noses => $self->noses, gates => $self->gates,
		curve => $self->curve, kinds => $self->kinds,
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

Version 0.05

=head1 SYNOPSIS

    my $world = Physics::Balls::World->from_table($table,
        mu => { s => 0.2, r => 0.015, sp => 0.044 },
        e  => { bb => 0.95, c => 0.8, cf => 0.2, rc => 0.7 },
        vmax => 8,
    );

    # or straight from geometry you built yourself, in metres
    my $world = Physics::Balls::World->new(L => 2.54, W => 1.27, R => 0.028575,
        walls => \@walls, noses => \@noses, gates => \@gates);

    # a surface whose balls curve: a green, with a jack and a bowl on each hand
    my $green = Physics::Balls::World->new(L => 9, W => 41, R => 0.0655,
        walls => \@box, noses => [], gates => \@ditches,
        mu => { s => 0.2, r => 0.0281, sp => 0.044 },
        curve => { k => 0.07, vref => 1, vmin => 0.25, p => 2, kmax => 0.6, cap => 0.002, vfrac => 0.1 },
        kinds => [ { curve => 0 }, { curve => 1 }, { curve => -1 } ],
    );

=head1 DESCRIPTION

Everything the engine needs to know before a strike. A world is built once
and shared between shots; the C engine behind it is created on the first
strike and freed with the world.

=head2 The curve

A ball of a kind whose C<curve> is not zero does not run straight. Its path
is a chain of parabolas that bends: at each of many small steps the engine
rotates the ball's velocity and its roll together through a small angle and
starts the next parabola, so every segment a client plays back is still a
segment and the turn adds no energy. The turn rate is

    k_per_second = k * curve * (vref / max(|v|, vmin)) ^ p

clamped to C<kmax>, a half-angle tangent per second, so that a slow ball
turns harder than a fast one, which is what a curling stone and a biased bowl
both do. B<This is a house law, a shape with fitted constants, and not a
model of ice or of a running surface.> Whoever describes a surface fits C<k>
to a number they can cite and says so. C<cap> is the half-angle tangent turned
in one step and C<vfrac> the largest fraction of its speed a ball may lose in
one step; smaller values cost segments and buy fidelity to the law.

=head1 ATTRIBUTES

=head2 L

=head2 W

=head2 R

The playing area and the ball radius, metres. C<R> is the radius of every
body whose kind gives none.

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

=head2 curve

The curve law's constants: C<k> (default 0, no ball curves whatever its
kind), C<vref> 1, C<vmin> 0.1, C<kmax> 1, C<p> an integer 0 to 4 (default 2),
C<cap> 0.002 and C<vfrac> 0.1.

=head2 kinds

A list of C<< { curve => $strength, follow => $share, r => $radius, m => $mass, mu => $factor, rs => $sweep, vfall => $speed } >>,
every member optional, indexed from 0 by a layout row's fourth element.
Default empty, which is a world where every ball is kind 0 at the world's
C<R>, mass 1, and none curves. The strength is signed and -1 to 1 by
convention: a bowl delivered on the other hand is the same bowl with the sign
flipped.

Since 0.04 a kind may also give a body its own size and weight. C<r> is its
radius in metres (default the world's C<R>); C<m> its mass, in any unit,
since only the ratios between kinds matter (default 1); C<mu> a multiplier
on the world's sliding and rolling friction under that body (default 1);
C<rs> the radius the body presents to bodies of its own kind (default C<r>),
which is how a toppling bowling pin reaches other pins wider than its belly
while the ball meets the belly itself; and C<vfall> a peak speed in metres
per second above which a body of the kind is down (default 0, never). A down
body leaves play when it comes to rest or slows under two centimetres a
second, as a potted ball leaves through a gate, and is listed in the
outcome's C<down> with where it lay. A world whose kinds give none of these
is bit for bit the world it was.

    kinds => [
        { r => 0.10795, m => 6.804 },                            # 0, a 15 lb bowling ball
        { r => 0.06053, rs => 0.078, m => 1.588, mu => 6, vfall => 0.25 },  # 1, a pin
    ]

C<follow>, default 1, is how much of its roll a body keeps through a contact
with another body. A ball keeps all of it, which is why a rolling cue ball
that hits full follows through, and 1 leaves the contact code exactly as it
was. A curling stone has no spin to keep and slides off at whatever velocity
the contact left it: that is 0, and it is the difference between a takeout
that stops on the shot and one that runs on for fifteen metres.

=head2 engine

The L<Physics::Balls::Engine>, built lazily.

=head1 METHODS

=head2 from_table

    my $world = Physics::Balls::World->from_table($table, %constants);

=head2 kind_count

How many kinds the world declares.

=head2 kind_radius

    my $r = $world->kind_radius($kind);

The radius of a kind, or the world's C<R> when the kind gives none.

=head2 kind_sweep

The radius a kind presents to its own kind, or its radius.

=head2 reach

    my $rho = $world->reach($kind_a, $kind_b);

The distance at which two bodies of those kinds touch: the sum of the sweep
radii between one kind, of the radii between two.

=head2 description

The hash the engine is built from.

=cut
