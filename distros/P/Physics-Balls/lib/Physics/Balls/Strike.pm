package Physics::Balls::Strike;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Physics::Balls::Error;
use Physics::Balls::Outcome;

our $VERSION = '0.05';

has ball => (
	is => 'ro',
	default => 0
);

has adjust => (
	is => 'ro',
	default => 0
);

has adjust_at => (
	is => 'ro',
	default => 0
);

has adjust_axis => (
	is => 'ro',
	default => 1
);

has adjust_dir => (
	is => 'ro',
	default => 1
);

has adjust_mu => (
	is => 'ro',
	default => 1000
);

has adjust_curve => (
	is => 'ro',
	default => 1000
);

has dx => (
	is => 'ro'
);

has dy => (
	is => 'ro'
);

has power => (
	is => 'ro'
);

has sx => (
	is => 'ro',
	default => 0
);

has sy => (
	is => 'ro',
	default => 0
);

has trace => (
	is => 'ro',
	default => 0
);

has tx => (
	is => 'ro',
	default => 0
);

has ty => (
	is => 'ro',
	default => 0
);

has spin => (
	is => 'ro',
	default => 0
);

sub _int { my ($v) = @_; return defined $v && $v =~ /\A-?\d+\z/ }

sub validate {
	my ($self, $world, $layout) = @_;
	my ($dx, $dy) = ($self->dx, $self->dy);
	return Physics::Balls::Error->of('bad_direction', 'dx ' . (defined $dx ? $dx : 'undef') . ', dy ' . (defined $dy ? $dy : 'undef'))
		unless _int($dx) && _int($dy) && abs($dx) <= 1_000_000 && abs($dy) <= 1_000_000 && ($dx != 0 || $dy != 0);
	return Physics::Balls::Error->of('bad_power', defined $self->power ? $self->power : 'undef')
		unless _int($self->power) && $self->power >= 0 && $self->power <= 1000;
	return Physics::Balls::Error->of('bad_spin', 'sx ' . $self->sx . ', sy ' . $self->sy)
		unless _int($self->sx) && _int($self->sy) && abs($self->sx) <= 500 && abs($self->sy) <= 500;
	if ($self->spin) {
		return Physics::Balls::Error->of('bad_roll', 'spin ' . $self->spin)
			unless _int($self->spin) && $self->spin >= 0 && $self->spin <= 1000;
		return Physics::Balls::Error->of('bad_roll', 'tx ' . (defined $self->tx ? $self->tx : 'undef') . ', ty ' . (defined $self->ty ? $self->ty : 'undef'))
			unless _int($self->tx) && _int($self->ty) && abs($self->tx) <= 1_000_000 && abs($self->ty) <= 1_000_000 && ($self->tx != 0 || $self->ty != 0);
	}
	if ($self->adjust) {
		return Physics::Balls::Error->of('bad_adjust', 'adjust_at ' . (defined $self->adjust_at ? $self->adjust_at : 'undef'))
			unless _int($self->adjust_at);
		return Physics::Balls::Error->of('bad_adjust', 'adjust_axis ' . (defined $self->adjust_axis ? $self->adjust_axis : 'undef'))
			unless _int($self->adjust_axis) && ($self->adjust_axis == 0 || $self->adjust_axis == 1);
		return Physics::Balls::Error->of('bad_adjust', 'adjust_dir ' . (defined $self->adjust_dir ? $self->adjust_dir : 'undef'))
			unless _int($self->adjust_dir) && ($self->adjust_dir == 1 || $self->adjust_dir == -1);
		for my $f (qw/adjust_mu adjust_curve/) {
			return Physics::Balls::Error->of('bad_adjust', "$f " . (defined $self->$f ? $self->$f : 'undef'))
				unless _int($self->$f) && $self->$f >= 0 && $self->$f <= 100000;
		}
	}
	return Physics::Balls::Error->of('bad_layout', 'not an array') unless ref $layout eq 'ARRAY';
	my (%seen, @rows);
	my $kinds = $world->kind_count || 1;
	for my $entry (@$layout) {
		my $row = ref $entry eq 'ARRAY' ? $entry : (ref $entry && $entry->can('row')) ? $entry->row : undef;
		return Physics::Balls::Error->of('bad_layout', 'an entry is not [id, x, y] or [id, x, y, kind]')
			unless $row && (@$row == 3 || @$row == 4) && _int($row->[0]) && _int($row->[1]) && _int($row->[2]);
		return Physics::Balls::Error->of('bad_kind', "ball $row->[0] kind " . (defined $row->[3] ? $row->[3] : 'undef') . " of $kinds")
			if @$row == 4 && !(_int($row->[3]) && $row->[3] >= 0 && $row->[3] < $kinds);
		return Physics::Balls::Error->of('bad_layout', "id $row->[0] appears twice") if $seen{ $row->[0] }++;
		push @rows, $row;
	}
	return Physics::Balls::Error->of('no_ball', 'ball ' . $self->ball) unless $seen{ $self->ball };
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
	return [ map { ref $_ eq 'ARRAY' ? $_ : $_->row } @$layout ];
}

sub play {
	my ($self, $world, $layout) = @_;
	my $err = $self->validate($world, $layout);
	return $err if $err;
	my %shot = (
		ball => $self->ball, dx => $self->dx, dy => $self->dy, power => $self->power,
		sx => $self->sx, sy => $self->sy,
	);
	if ($self->adjust) {
		%shot = (%shot, adjust => 1, adjust_at => $self->adjust_at, adjust_axis => $self->adjust_axis,
			adjust_dir => $self->adjust_dir, adjust_mu => $self->adjust_mu, adjust_curve => $self->adjust_curve);
	}
	if ($self->spin) {
		%shot = (%shot, tx => $self->tx, ty => $self->ty, spin => $self->spin);
	}
	my $raw = $world->engine->strike($self->rows($layout), { %shot, trace => $self->trace ? 1 : 0 });
	return Physics::Balls::Error->of('engine', $raw->{error})
		if defined $raw->{error} && ($raw->{error} eq 'no_ball' || $raw->{error} eq 'kind' || $raw->{error} eq 'size');
	return Physics::Balls::Outcome->new(
		t => $raw->{t}, n => $raw->{n}, error => $raw->{error},
		events => $raw->{events}, rest => $raw->{rest}, holed => $raw->{holed},
		segments => $raw->{segments}, energy => $raw->{energy} || [],
		down => $raw->{down} || [], peak => $raw->{peak} || {},
		kinded => (grep { $_->{r} || $_->{m} || $_->{mu} || $_->{rs} || $_->{vfall} } @{ $world->kinds }) ? 1 : 0,
		shot => \%shot,
	);
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Strike - one shot, as the integers a client sends

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    my $strike = Physics::Balls::Strike->new(ball => 0, dx => 707107, dy => -707107, power => 640, sx => 0, sy => 300);
    my $out = $strike->play($world, \@layout);

    # a delivery whose surface changes once it passes y = 32.007 m
    my $swept = Physics::Balls::Strike->new(ball => 7, dx => 0, dy => 1_000_000, power => 500, sy => 400,
        adjust => 1, adjust_at => 3200700, adjust_axis => 1, adjust_dir => 1, adjust_mu => 600, adjust_curve => 350);

=head1 DESCRIPTION

The direction is C<dx, dy> in plus or minus 1,000,000 (normalised inside the
engine with one square root), C<power> 0 to 1000 (the speed is
C<0.3 + (power/1000)^2 (vmax - 0.3)> so low power is fine-grained), and the tip
offset C<sx, sy> in thousandths of the radius, clamped to half a radius.
Integers, so that a client cannot send a float two encoders would spell
differently. C<validate> refuses anything else with a L<Physics::Balls::Error>
rather than dying.

=head2 The adjust

A shot may say that the surface under the struck ball changes partway down
its run: once the ball's centre crosses a line, in one direction, its
friction and its curve are multiplied by two factors, once, for the rest of
the shot. That is a swept path, a fast strip or a damp patch; the engine does
not know which. The crossing is an C<adjust> event in the outcome, and every
segment before it is bit-identical to the same delivery with no adjust, which
is what lets a game show a delivery, ask a question at the line, and then
play the same delivery again with the answer applied.

=head2 The release roll

Since 0.04 a shot may say how the ball is rolling when it leaves the hand:
C<spin> is the size of its roll velocity in thousandths of its speed, 0 to
1000, and C<tx, ty> the roll's direction in plus or minus 1,000,000. A roll
along the line of the shot is what the tip offset C<sy> gives; a roll across
it makes the ball slide on a parabola until its slip closes, which is how a
bowling ball hooks. With C<spin> 0 the shot is exactly what it was.

    my $hook = Physics::Balls::Strike->new(ball => 0, dx => 0, dy => 1_000_000, power => 915,
        tx => -566529, ty => 824042, spin => 485);

=head1 ATTRIBUTES

=head2 ball

The id struck, default 0.

=head2 dx

=head2 dy

=head2 power

=head2 sx

=head2 sy

=head2 trace

When true the outcome carries the energy after every event.

=head2 adjust

True to apply the adjust; default 0, and then the other adjust fields are
ignored.

=head2 adjust_at

The line, an integer in hundredths of a millimetre.

=head2 adjust_axis

0 for a line of constant x, 1 for a line of constant y; default 1.

=head2 adjust_dir

1 to fire when the coordinate increases through the line, -1 when it
decreases; default 1.

=head2 adjust_mu

=head2 adjust_curve

The factors in thousandths, default 1000 (unchanged).

=head2 tx

=head2 ty

=head2 spin

The release roll: a direction in plus or minus 1,000,000 and a size in
thousandths of the release speed, 0 to 1000. Default 0, no roll beyond the
tip offset's.

=head1 METHODS

=head2 validate

    my $err = $strike->validate($world, \@layout);

Undef when the shot and the layout are acceptable, else the error. Two balls
may sit touching, and a tenth of a millimetre inside each other, because a
tight rack rounded to hundredths does that and the engine treats it as
contact; any closer is C<overlap>. The touching distance is the world's
C<reach> for the two rows' kinds.

=head2 rows

The layout as plain rows, whatever it was given as.

=head2 play

    my $out = $strike->play($world, \@layout);

A L<Physics::Balls::Outcome>, or the L<Physics::Balls::Error> that refused it.

=cut
