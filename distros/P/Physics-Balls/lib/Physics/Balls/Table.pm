package Physics::Balls::Table;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.05';

my $SQRT2 = sqrt 2;
my $PI = 4 * atan2(1, 1);

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

has corner => (
	is => 'ro',
	isa => HashRef
);

has side => (
	is => 'ro',
	isa => HashRef
);

has geometry => (
	is => 'ro',
	lazy => 1,
	builder => 1
);

sub BUILD {
	my ($self) = @_;
	for my $f (qw/L W R/) {
		die "Physics::Balls::Table: $f must be positive" unless defined $self->$f && $self->$f > 0;
	}
	for my $p (qw/corner side/) {
		my $h = $self->$p;
		die "Physics::Balls::Table: $p needs mouth, jaw_deg and shelf"
			unless ref $h eq 'HASH' && defined $h->{mouth} && defined $h->{jaw_deg} && defined $h->{shelf};
	}
	return $self;
}

sub _rot {
	my ($v, $deg) = @_;
	my $a = $deg * $PI / 180;
	my ($c, $s) = (cos $a, sin $a);
	return [ $v->[0] * $c - $v->[1] * $s, $v->[0] * $s + $v->[1] * $c ];
}

sub _cup {
	my ($N1, $e1, $N2, $e2, $u, $spec, $R) = @_;
	my $turn = 180 - $spec->{jaw_deg};
	my $w1 = _rot($e1, -$turn);
	my $w2 = _rot([ -$e2->[0], -$e2->[1] ], $turn);
	my $back = $spec->{shelf} + $R * 1.25;
	my $k1 = $w1->[0] * $u->[0] + $w1->[1] * $u->[1];
	my $k2 = $w2->[0] * $u->[0] + $w2->[1] * $u->[1];
	my $J1 = [ $N1->[0] + $w1->[0] * $back / $k1, $N1->[1] + $w1->[1] * $back / $k1 ];
	my $J2 = [ $N2->[0] + $w2->[0] * $back / $k2, $N2->[1] + $w2->[1] * $back / $k2 ];
	my $G1 = [ $N1->[0] + $w1->[0] * $spec->{shelf} / $k1, $N1->[1] + $w1->[1] * $spec->{shelf} / $k1 ];
	my $G2 = [ $N2->[0] + $w2->[0] * $spec->{shelf} / $k2, $N2->[1] + $w2->[1] * $spec->{shelf} / $k2 ];
	my $M = [ ($N1->[0] + $N2->[0]) / 2, ($N1->[1] + $N2->[1]) / 2 ];
	return {
		points => [ $N1, $J1, $J2, $N2 ],
		gate => { x1 => $G1->[0], y1 => $G1->[1], x2 => $G2->[0], y2 => $G2->[1], nx => $u->[0], ny => $u->[1] },
		hole => { x => $M->[0] + $u->[0] * ($spec->{shelf} + 0.75 * $R), y => $M->[1] + $u->[1] * ($spec->{shelf} + 0.75 * $R), r => 1.3 * $R },
		mouth => [ $N1, $N2 ],
		u => $u,
	};
}

sub _build_geometry {
	my ($self) = @_;
	my ($L, $W, $R) = ($self->L, $self->W, $self->R);
	my $a = $self->corner->{mouth} / $SQRT2;
	my $ms = $self->side->{mouth} / 2;
	my (@pts, @pockets);
	my $add = sub {
		my ($cp) = @_;
		push @pts, @{ $cp->{points} };
		$cp->{index} = scalar @pockets;
		push @pockets, $cp;
	};
	my $c = $self->corner;
	my $s = $self->side;
	$add->(_cup([ 0, $a ], [ 0, -1 ], [ $a, 0 ], [ 1, 0 ], [ -1 / $SQRT2, -1 / $SQRT2 ], $c, $R));
	$add->(_cup([ $L / 2 - $ms, 0 ], [ 1, 0 ], [ $L / 2 + $ms, 0 ], [ 1, 0 ], [ 0, -1 ], $s, $R));
	$add->(_cup([ $L - $a, 0 ], [ 1, 0 ], [ $L, $a ], [ 0, 1 ], [ 1 / $SQRT2, -1 / $SQRT2 ], $c, $R));
	$add->(_cup([ $L, $W - $a ], [ 0, 1 ], [ $L - $a, $W ], [ -1, 0 ], [ 1 / $SQRT2, 1 / $SQRT2 ], $c, $R));
	$add->(_cup([ $L / 2 + $ms, $W ], [ -1, 0 ], [ $L / 2 - $ms, $W ], [ -1, 0 ], [ 0, 1 ], $s, $R));
	$add->(_cup([ $a, $W ], [ -1, 0 ], [ 0, $W - $a ], [ 0, -1 ], [ -1 / $SQRT2, 1 / $SQRT2 ], $c, $R));
	my @walls;
	for my $i (0 .. $#pts) {
		my ($p, $q) = ($pts[$i], $pts[ ($i + 1) % @pts ]);
		push @walls, [ $p->[0], $p->[1], $q->[0], $q->[1] ];
	}
	my @gates = map { my $g = $_->{gate}; [ $g->{x1}, $g->{y1}, $g->{x2}, $g->{y2}, $g->{nx}, $g->{ny}, $_->{index} ] } @pockets;
	return {
		points => \@pts,
		walls => \@walls,
		noses => [ map { [ $_->[0], $_->[1] ] } @pts ],
		gates => \@gates,
		pockets => \@pockets,
	};
}

sub walls { return $_[0]->geometry->{walls} }
sub noses { return $_[0]->geometry->{noses} }
sub gates { return $_[0]->geometry->{gates} }
sub pockets { return $_[0]->geometry->{pockets} }
sub points { return $_[0]->geometry->{points} }

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Table - a rectangular table with six pockets, as walls, noses and gates

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    my $table = Physics::Balls::Table->new(
        L => 3.569, W => 1.778, R => 0.02625,
        corner => { mouth => 0.086, jaw_deg => 142, shelf => 0.030 },
        side   => { mouth => 0.095, jaw_deg => 104, shelf => 0.008 },
    );
    my $walls = $table->walls;     # 24 segments, cloth on the left
    my $gates = $table->gates;     # 6 capture lines, one per pocket

=head1 DESCRIPTION

Geometry only, in whatever unit you give it (metres for the engine). The
playing area is C<L> by C<W> between the cushion noses; each pocket is a cup
whose jaws leave the cushion line at the cut angle and run to a back wall deep
enough for a ball's centre to cross the gate, and the gate sits C<shelf> beyond
the line between the noses. The boundary is walked counter-clockwise, so every
wall's left normal points into play, and every vertex is a nose point a ball
can rattle off. Pockets are numbered bottom-left, bottom side, bottom-right,
top-right, top side, top-left, with the long side along C<L>.

What the numbers should be is a game's business: the WPA publishes a pool
table's, the WPBSA rulebook does not publish snooker's.

=head1 ATTRIBUTES

=head2 L

=head2 W

=head2 R

The playing area and the ball radius.

=head2 corner

=head2 side

Hashes of C<mouth> (between the noses), C<jaw_deg> (the cut angle) and
C<shelf> (from the mouth line to the drop).

=head2 geometry

The built hash: C<points>, C<walls>, C<noses>, C<gates>, C<pockets>.

=head1 METHODS

=head2 walls

C<[x1, y1, x2, y2]> per wall.

=head2 noses

C<[x, y]> per vertex.

=head2 gates

C<[x1, y1, x2, y2, nx, ny, pocket]> per pocket, the normal into the pocket.

=head2 pockets

One hash per pocket: C<points>, C<gate>, C<hole> (where to draw it), C<mouth>,
C<u> (the axis into the pocket), C<index>.

=head2 points

The boundary, counter-clockwise.

=cut
