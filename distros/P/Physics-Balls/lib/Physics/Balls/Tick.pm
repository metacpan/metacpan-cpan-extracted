package Physics::Balls::Tick;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Physics::Balls::Error;
use Physics::Balls::Outcome;

our $VERSION = '0.07';

has t => (
	is => 'ro',
	default => 20000
);

has trace => (
	is => 'ro',
	default => 0
);

sub _int { my ($v) = @_; return defined $v && $v =~ /\A-?\d+\z/ }

sub validate {
	my ($self, $world, $layout) = @_;
	return Physics::Balls::Error->of('bad_horizon', defined $self->t ? $self->t : 'undef')
		unless _int($self->t) && $self->t > 0 && $self->t <= 40_000_000;
	return Physics::Balls::Error->of('bad_layout', 'not an array') unless ref $layout eq 'ARRAY';
	my (%seen, @rows);
	my $kinds = $world->kind_count || 1;
	for my $entry (@$layout) {
		my $row = ref $entry eq 'ARRAY' ? $entry : (ref $entry && $entry->can('moving_row')) ? $entry->moving_row : undef;
		return Physics::Balls::Error->of('bad_layout', 'an entry is not [id, x, y, kind, vx, vy]')
			unless $row && @$row == 6 && _int($row->[0]) && _int($row->[1]) && _int($row->[2]) && _int($row->[3]);
		return Physics::Balls::Error->of('bad_kind', "ball $row->[0] kind $row->[3] of $kinds")
			unless $row->[3] >= 0 && $row->[3] < $kinds;
		return Physics::Balls::Error->of('bad_velocity', "ball $row->[0] vx " . (defined $row->[4] ? $row->[4] : 'undef') . ', vy ' . (defined $row->[5] ? $row->[5] : 'undef'))
			unless _int($row->[4]) && _int($row->[5]) && abs($row->[4]) <= 100_000_000 && abs($row->[5]) <= 100_000_000;
		return Physics::Balls::Error->of('bad_layout', "id $row->[0] appears twice") if $seen{ $row->[0] }++;
		push @rows, $row;
	}
	for my $i (0 .. $#rows) {
		for my $j ($i + 1 .. $#rows) {
			my $min = $world->reach($rows[$i][3], $rows[$j][3]) * 1e5 - 10;
			my $dxx = $rows[$i][1] - $rows[$j][1];
			my $dyy = $rows[$i][2] - $rows[$j][2];
			return Physics::Balls::Error->of('overlap', "balls $rows[$i][0] and $rows[$j][0]")
				if $dxx * $dxx + $dyy * $dyy < $min * $min;
		}
	}
	return;
}

sub rows {
	my ($self, $layout) = @_;
	return [ map { ref $_ eq 'ARRAY' ? $_ : $_->moving_row } @$layout ];
}

sub play {
	my ($self, $world, $layout) = @_;
	my $err = $self->validate($world, $layout);
	return $err if $err;
	my $raw = $world->engine->advance($self->rows($layout), { t => $self->t, trace => $self->trace ? 1 : 0 });
	return Physics::Balls::Error->of('engine', $raw->{error})
		if defined $raw->{error} && ($raw->{error} eq 'kind' || $raw->{error} eq 'size' || $raw->{error} eq 'horizon');
	return Physics::Balls::Outcome->new(
		t => $raw->{t}, n => $raw->{n}, error => $raw->{error},
		events => $raw->{events}, rest => $raw->{rest}, holed => $raw->{holed},
		segments => $raw->{segments}, energy => $raw->{energy} || [],
		down => $raw->{down} || [], peak => $raw->{peak} || {},
		state => $raw->{state} || [],
		kinded => (grep { $_->{r} || $_->{m} || $_->{mu} || $_->{rs} || $_->{vfall} } @{ $world->kinds }) ? 1 : 0,
		shot => { t => $self->t },
	);
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Tick - one advance to a horizon, for a game that ticks

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    my $tick = Physics::Balls::Tick->new(t => 20000);
    my $out  = $tick->play($world, [ [0, 50000, 100000, 0, 0, 300000], [1, 50000, 5000, 1, 0, 0] ]);
    my $rows = $out->state;    # [[id, x, y, vx, vy, mode], ...] at the horizon

=head1 DESCRIPTION

A strike releases one ball and runs until everything rests. A live game
cannot wait for that: it ticks, sets what it drives (a mallet, a paddle) to a
velocity of its own each tick, and needs every body's position and velocity
exactly one tick later. This is that call, since 0.07: every row may carry a
starting velocity, in hundredths of a millimetre a second, the world is
advanced exactly C<t> microseconds, and the outcome's C<state> holds every body
at the horizon. Integers throughout, so a tick's state is the next tick's row
and every encoder spells it the same way.

A body with a velocity is released rolling, with its roll equal to its
velocity, and no speed floor applies. An event at exactly the horizon belongs
to the next call. The settle pass runs at the horizon as it does at rest. A
kind's C<follow> of 0 keeps the roll equal to the velocity through every
contact, and a world with C<rc> 1 and C<cf> 0 keeps it so off a cushion, which
is what makes C<[x, y, vx, vy]> the whole state to carry.

=head1 ATTRIBUTES

=head2 t

The horizon in microseconds, an integer from 1 to 40,000,000; default 20000.

=head2 trace

When true the outcome carries the energy after every event.

=head1 METHODS

=head2 validate

    my $err = $tick->validate($world, \@layout);

Undef when the layout is acceptable, else the L<Physics::Balls::Error>: rows
of six integers with distinct ids and kinds the world declares, velocities
within plus or minus 100,000,000 (1000 m/s), no two bodies more than a tenth
of a millimetre inside each other, and a horizon in range.

=head2 rows

The layout as plain rows, whatever it was given as.

=head2 play

    my $out = $tick->play($world, \@layout);

A L<Physics::Balls::Outcome> with C<state> filled, or the error that refused
it.

=cut
