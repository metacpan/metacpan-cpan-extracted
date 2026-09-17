package Physics::Balls::Outcome;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.02';

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

has shot => (
	is => 'ro',
	isa => HashRef,
	default => {}
);

sub message {
	my ($self) = @_;
	return '' unless $self->error;
	return $self->error eq 'events' ? 'the engine gave up after 5000 events'
		: $self->error eq 'time' ? 'the engine gave up after 40 seconds of simulated time'
		: 'the engine failed: ' . $self->error;
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

sub contacts {
	my ($self) = @_;
	return [ grep { $_->[1] ne 'roll' && $_->[1] ne 'stop' } @{ $self->events } ];
}

sub to_payload {
	my ($self) = @_;
	return {
		engine => 1,
		t => $self->t, n => $self->n,
		error => $self->error,
		events => $self->events, rest => $self->rest, holed => $self->holed,
		segments => $self->segments,
	};
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Outcome - what a strike did

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $out = $strike->play($world, \@layout);
    my $first = $out->first(0);          # the ball the cue ball met first, or undef
    my @pots  = @{ $out->holed };        # [id, pocket, t] in time order
    my $rest  = $out->rest;              # [id, x, y] for every ball in play
    my $segs  = $out->segments->{0};     # the cue ball's trajectory, segment by segment

=head1 DESCRIPTION

The record of one shot. C<events> is every event in time order as
C<[t, kind, a, b]>: C<roll> and C<stop> for one ball, C<ball> for two, C<wall>
and C<nose> with the wall or nose index, C<pot> with the pocket number. A rules
module reads first contact, cushions after contact and pots in order straight
off it. C<segments> is the trajectory a client plays back, per ball id, each
C<[t0, dur, px, py, vx, vy, ax, ay]> in metres and seconds, so a position at
time C<t> within a segment is C<p0 + v (t - t0) + a (t - t0)^2 / 2>.

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

Per unit mass after the strike and after every event, when the strike was
traced; else empty.

=head2 shot

The shot that produced this.

=head1 METHODS

=head2 message

A sentence for C<error>, or the empty string.

=head2 first

    my $other = $out->first($id);

The first ball C<$id> met, or undef when it met a wall, a nose or a pocket
first or nothing at all.

=head2 walls_touched

The wall and nose events for a ball.

=head2 potted

    my $h = $out->potted($id);

The C<[id, pocket, t]> row, or undef.

=head2 contacts

The events that are contacts, without the roll and stop transitions.

=head2 to_payload

The hash a game stores and a client plays back: C<engine>, C<t>, C<n>,
C<error>, C<events>, C<rest>, C<holed>, C<segments>.

=cut
