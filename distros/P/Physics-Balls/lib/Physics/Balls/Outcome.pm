package Physics::Balls::Outcome;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.07';

has t => (
	is => 'ro',
	isa => Num
);

has n => (
	is => 'ro',
	isa => Int
);

has error => (
	is => 'ro'
);

has events => (
	is => 'ro',
	isa => ArrayRef
);

has rest => (
	is => 'ro',
	isa => ArrayRef
);

has holed => (
	is => 'ro',
	isa => ArrayRef
);

has segments => (
	is => 'ro',
	isa => HashRef
);

has energy => (
	is => 'ro',
	isa => ArrayRef,
	default => []
);

has down => (
	is => 'ro',
	isa => ArrayRef,
	default => []
);

has peak => (
	is => 'ro',
	isa => HashRef,
	default => {}
);

has shot => (
	is => 'ro',
	isa => HashRef,
	default => {}
);

has kinded => (
	is => 'ro',
	default => 0
);

has state => (
	is => 'ro',
	isa => ArrayRef,
	default => []
);

our @MODE = qw/stationary sliding rolling pocketed/;

sub state_of {
	my ($self, $id) = @_;
	for my $s (@{ $self->state }) { return $s if $s->[0] == $id }
	return;
}

sub mode_of {
	my ($self, $id) = @_;
	my $s = $self->state_of($id) or return;
	return $MODE[ $s->[5] ];
}

sub message {
	my ($self) = @_;
	return '' unless $self->error;
	return $self->error eq 'events' ? 'the engine gave up after 5000 events'
		: $self->error eq 'time' ? 'the engine gave up after 40 seconds of simulated time'
		: $self->error eq 'turns' ? 'the engine gave up after 20000 turns of curving balls'
		: 'the engine failed: ' . $self->error;
}

sub adjusted_at {
	my ($self) = @_;
	for my $e (@{ $self->events }) { return $e->[0] if $e->[1] eq 'adjust' }
	return;
}

sub first {
	my ($self, $id) = @_;
	for my $e (@{ $self->events }) {
		my ($t, $kind, $a, $b) = @$e;
		if ($kind eq 'ball' && ($a == $id || $b == $id)) { return $a == $id ? $b : $a }
		return if ($kind eq 'wall' || $kind eq 'nose' || $kind eq 'pot') && $a == $id;
	}
	return;
}

sub walls_touched {
	my ($self, $id) = @_;
	return [ grep { ($_->[1] eq 'wall' || $_->[1] eq 'nose') && $_->[2] == $id } @{ $self->events } ];
}

sub potted {
	my ($self, $id) = @_;
	for my $h (@{ $self->holed }) { return $h if $h->[0] == $id }
	return;
}

sub downed {
	my ($self, $id) = @_;
	for my $d (@{ $self->down }) { return $d if $d->[0] == $id }
	return;
}

sub peak_of {
	my ($self, $id) = @_;
	return $self->peak->{$id};
}

sub contacts {
	my ($self) = @_;
	return [ grep { $_->[1] ne 'roll' && $_->[1] ne 'stop' && $_->[1] ne 'adjust' && $_->[1] ne 'down' } @{ $self->events } ];
}

sub to_payload {
	my ($self) = @_;
	return {
		engine => 1,
		t => $self->t, n => $self->n,
		error => $self->error,
		events => $self->events, rest => $self->rest, holed => $self->holed,
		segments => $self->segments,
		$self->kinded ? (down => $self->down, peak => $self->peak) : (),
		@{ $self->state } ? (state => $self->state) : (),
	};
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Outcome - what a strike did

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    my $out = $strike->play($world, \@layout);
    my $first = $out->first(0);          # the ball the cue ball met first, or undef
    my @pots  = @{ $out->holed };        # [id, pocket, t] in time order
    my $rest  = $out->rest;              # [id, x, y] for every ball in play
    my $segs  = $out->segments->{0};     # the cue ball's trajectory, segment by segment

=head1 DESCRIPTION

The record of one shot. C<events> is every event in time order as
C<[t, kind, a, b]>: C<roll> and C<stop> for one ball, C<ball> for two, C<wall>
and C<nose> with the wall or nose index, C<pot> with the pocket number, and
C<adjust> for the struck ball when the shot carried one. A rules module reads
first contact, cushions after contact and pots in order straight off it.
C<down> (0.04) is every body that passed its kind's C<vfall> and left play,
C<[id, x, y, t]> in time order, where it lay in hundredths of a millimetre
and when; such a body is in neither C<rest> nor C<holed>. C<peak> is every
body's peak speed over the shot, by id, in metres per second: the number a
pinfall rule reads.
C<segments> is the trajectory a client plays back, per ball id, each
C<[t0, dur, px, py, vx, vy, ax, ay]> in metres and seconds, so a position at
time C<t> within a segment is C<p0 + v (t - t0) + a (t - t0)^2 / 2>. A curving
ball's trajectory is many short segments; a client plays them exactly as it
plays a straight ball's, because each one is still that parabola.

=head1 ATTRIBUTES

=head2 t

Simulated seconds until the last ball stopped.

=head2 n

Events processed.

=head2 error

Undef, or C<events> or C<time> when the engine gave up; an outcome with an
error is still returned so a caller can see how far it got.

=head2 events

=head2 rest

=head2 holed

=head2 segments

=head2 energy

Mass-weighted (per unit mass when every body is the default kind), after the
strike and after every event, when the strike was traced; else empty.

=head2 down

=head2 peak

As described above.

=head2 kinded

True when the world the shot was played on declares a kind with a size, a
mass, a friction or a down threshold of its own; then C<to_payload> carries
C<down> and C<peak>.

=head2 shot

The shot that produced this; for an advance, C<< { t => $microseconds } >>.

=head2 state

Since 0.07, from an advance only: every body at the horizon, in layout order,
as C<[id, x, y, vx, vy, mode]> in hundredths of a millimetre and hundredths of
a millimetre a second, C<mode> 0 stationary, 1 sliding, 2 rolling, 3
pocketed. Empty for a strike. C<to_payload> carries it when it is not empty.

=head1 METHODS

=head2 state_of

    my $row = $out->state_of($id);

A body's state row at the horizon, or undef.

=head2 mode_of

    my $word = $out->mode_of($id);    # 'rolling'

The body's mode at the horizon as a word, or undef.

=head2 message

A sentence for C<error>, or the empty string.

=head2 adjusted_at

The time the struck ball crossed the shot's adjust line, or undef when the
shot carried no adjust or the ball never reached the line.

=head2 first

    my $other = $out->first($id);

The first ball C<$id> met, or undef when it met a wall, a nose or a pocket
first or nothing at all.

=head2 walls_touched

The wall and nose events for a ball.

=head2 potted

    my $h = $out->potted($id);

The C<[id, pocket, t]> row, or undef.

=head2 downed

    my $d = $out->downed($id);

The C<[id, x, y, t]> row of a body that went down, or undef.

=head2 peak_of

    my $v = $out->peak_of($id);

A body's peak speed over the shot.

=head2 contacts

The events that are contacts, without the roll, stop, adjust and down
transitions.

=head2 to_payload

The hash a game stores and a client plays back: C<engine>, C<t>, C<n>,
C<error>, C<events>, C<rest>, C<holed>, C<segments>, and C<down> and C<peak>
when the world is C<kinded>; a pool payload is what it always was.

=cut
