package Physics::Balls::Strike;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Physics::Balls::Error;
use Physics::Balls::Outcome;

our $VERSION = '0.01';

has ball => (
	is => 'ro',
	default => 0
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
	return Physics::Balls::Error->of('bad_layout', 'not an array') unless ref $layout eq 'ARRAY';
	my (%seen, @rows);
	for my $entry (@$layout) {
		my $row = ref $entry eq 'ARRAY' ? $entry : (ref $entry && $entry->can('row')) ? $entry->row : undef;
		return Physics::Balls::Error->of('bad_layout', 'an entry is not [id, x, y]')
			unless $row && @$row == 3 && _int($row->[0]) && _int($row->[1]) && _int($row->[2]);
		return Physics::Balls::Error->of('bad_layout', "id $row->[0] appears twice") if $seen{ $row->[0] }++;
		push @rows, $row;
	}
	return Physics::Balls::Error->of('no_ball', 'ball ' . $self->ball) unless $seen{ $self->ball };
	my $min = 2 * $world->R * 1e5 - 10;
	for my $i (0 .. $#rows) {
		for my $j ($i + 1 .. $#rows) {
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
	my $raw = $world->engine->strike($self->rows($layout), {
		ball => $self->ball, dx => $self->dx, dy => $self->dy, power => $self->power,
		sx => $self->sx, sy => $self->sy, trace => $self->trace ? 1 : 0,
	});
	return Physics::Balls::Error->of('engine', $raw->{error}) if defined $raw->{error} && $raw->{error} eq 'no_ball';
	return Physics::Balls::Outcome->new(
		t => $raw->{t}, n => $raw->{n}, error => $raw->{error},
		events => $raw->{events}, rest => $raw->{rest}, holed => $raw->{holed},
		segments => $raw->{segments}, energy => $raw->{energy} || [],
		shot => { ball => $self->ball, dx => $self->dx, dy => $self->dy, power => $self->power, sx => $self->sx, sy => $self->sy },
	);
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Strike - one shot, as the integers a client sends

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $strike = Physics::Balls::Strike->new(ball => 0, dx => 707107, dy => -707107, power => 640, sx => 0, sy => 300);
    my $out = $strike->play($world, \@layout);

=head1 DESCRIPTION

The direction is C<dx, dy> in plus or minus 1,000,000 (normalised inside the
engine with one square root), C<power> 0 to 1000 (the speed is
C<0.3 + (power/1000)^2 (vmax - 0.3)> so low power is fine-grained), and the tip
offset C<sx, sy> in thousandths of the radius, clamped to half a radius.
Integers, so that a client cannot send a float two encoders would spell
differently. C<validate> refuses anything else with a L<Physics::Balls::Error>
rather than dying.

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

=head1 METHODS

=head2 validate

    my $err = $strike->validate($world, \@layout);

Undef when the shot and the layout are acceptable, else the error. Two balls
may sit touching, and a tenth of a millimetre inside each other, because a
tight rack rounded to hundredths does that and the engine treats it as
contact; any closer is C<overlap>.

=head2 rows

The layout as plain rows, whatever it was given as.

=head2 play

    my $out = $strike->play($world, \@layout);

A L<Physics::Balls::Outcome>, or the L<Physics::Balls::Error> that refused it.

=cut
