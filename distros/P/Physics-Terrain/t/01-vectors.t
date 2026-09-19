#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The hand-derived correctness vectors from plan_crater/01-the-prototype.md's
# mark 4, derived here without the engine and compared exactly:
#
#   - a shell with no wind is at x = x0 + t vx, y = y0 + t vy + G t(t+1)/2
#     after t moves, and it lands on the first move whose row reaches the
#     floor; the crater is in the row above the floor in a column the
#     segment of that move crosses there. The engine's event tick is t - 1
#     because the shot fires before the move of tick 0;
#   - a body dropped h cells lands on the first tick t with G t(t+1)/2 >= 256 h;
#   - a crater of radius r clears exactly the cells with dx*dx + dy*dy <= r*r.

use Physics::Terrain;

my $G = 12;
my $FLOOR = 400;
my @ranges = ([512, 60], [512, 100], [300, 80], [900, 45], [1536, 70], [2448, 90], [1000, 100]);
my @drops = (1, 2, 5, 13, 40, 100, 250);
my @radii = (1 .. 45);

plan tests => @ranges + 2 * @drops + 2 * @radii;

# every cell a segment between two cell centres touches, Amanatides and Woo
sub cells_touched {
	my ($x0, $y0, $x1, $y1) = @_;
	my @out = ([$x0, $y0]);
	my ($x, $y) = ($x0, $y0);
	my ($dx, $dy) = ($x1 - $x0, $y1 - $y0);
	my ($sx, $sy) = ($dx <=> 0, $dy <=> 0);
	my ($tmx, $tmy) = ($dx == 0 ? 9e99 : 0.5 / abs $dx, $dy == 0 ? 9e99 : 0.5 / abs $dy);
	my ($tdx, $tdy) = ($dx == 0 ? 9e99 : 1 / abs $dx, $dy == 0 ? 9e99 : 1 / abs $dy);
	while ($x != $x1 || $y != $y1) {
		if (abs($tmx - $tmy) < 1e-12) { $x += $sx; $y += $sy; $tmx += $tdx; $tmy += $tdy; push @out, [$x - $sx, $y], [$x, $y - $sy] }
		elsif ($tmx < $tmy) { $x += $sx; $tmx += $tdx }
		else { $y += $sy; $tmy += $tdy }
		push @out, [$x, $y];
		die 'runaway' if @out > 100000;
	}
	return @out;
}

for my $v (@ranges) {
	my ($angle, $power) = @$v;
	my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'flat', floor => $FLOOR }, bodies => [[0, 640, 0]], wind => 0);
	my ($vx, $vy) = Physics::Terrain->launch(0, $angle, $power);
	my $out = $field->run_turn(0, [], { tick => 0, weapon => 0, angle => $angle, power => $power });
	my $first = $out->{trace}{shots}[0][0];
	my ($x0, $y0) = ($first->[1], $first->[2]);
	my ($t, $px, $py, $x, $y, $landed) = (0, $x0, $y0, $x0, $y0, undef);
	while ($t < 5000) {
		$t++;
		$x = $x0 + $t * $vx;
		$y = $y0 + $t * $vy + $G * $t * ($t + 1) / 2;
		die 'terminal velocity: pick another vector' if $vy + $G * $t > 2400;
		my ($cx, $cy) = (floor256($x), floor256($y));
		if ($cy >= $FLOOR || $cx < 0 || $cx >= 1280) {
			my %columns;
			for my $c (cells_touched(floor256($px), floor256($py), $cx, $cy)) {
				last if $c->[1] >= $FLOOR;
				$columns{ $c->[0] } = 1 if $c->[1] == $FLOOR - 1;
			}
			$landed = { t => $t, columns => \%columns, out => ($cx < 0 || $cx >= 1280) };
			last;
		}
		($px, $py) = ($x, $y);
	}
	my ($ex) = grep { $_->[1] eq 'explode' } @{ $out->{events} };
	if ($landed->{out}) {
		ok !$ex, "range $angle/$power leaves the field, as derived";
	} else {
		ok $ex && $ex->[0] == $landed->{t} - 1 && $ex->[3] == $FLOOR - 1 && $landed->{columns}{ $ex->[2] },
			"range $angle/$power: derived tick " . ($landed->{t} - 1) . " row " . ($FLOOR - 1) . " columns [" . join(' ', sort { $a <=> $b } keys %{ $landed->{columns} }) . "], engine " . ($ex ? "tick $ex->[0] cell $ex->[2],$ex->[3]" : 'never exploded');
	}
}

for my $h (@drops) {
	my $floor = 500;
	my $ledge = $floor - $h;
	my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'flat', floor => $floor },
		sculpt => [['fill', 600, $ledge, 680, $ledge]], bodies => [[0, 640, 0]], wind => 0);
	is $field->body(0)->{y}, 256 * $ledge, "drop $h: the body stands on the ledge";
	$field->sculpt([['clear', 560, $ledge, 720, $ledge]]);
	my $t = 0;
	$t++ while $G * $t * ($t + 1) / 2 < 256 * $h;
	$field->start_turn(0);
	my $landed = -1;
	for my $k (0 .. 1999) {
		$field->advance(0, $k == 0 ? { weapon => 2, angle => 1024, power => 1 } : undef);
		if ($field->body(0)->{mode} == Physics::Terrain::STANDING()) { $landed = $field->turn_tick; last }
	}
	is $landed, $t, "drop $h cells: lands on tick $t, feet at " . $field->body(0)->{y} . " (expected " . 256 * $floor . ")";
}

for my $r (@radii) {
	my $expected = 0;
	for my $dy (-$r .. $r) { for my $dx (-$r .. $r) { $expected++ if $dx * $dx + $dy * $dy <= $r * $r } }
	my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'empty' }, place => 'none');
	$field->sculpt([['fill', 0, 0, 1279, 639]]);
	my $cleared = $field->carve(640, 320, $r);
	is $cleared, $expected, "crater r=$r clears $expected cells";
	is 1280 * 640 - $field->count, $expected, "crater r=$r: the mask lost exactly those";
}

sub floor256 { my ($v) = @_; my $q = int($v / 256); $q-- if $q * 256 > $v; return $q }
