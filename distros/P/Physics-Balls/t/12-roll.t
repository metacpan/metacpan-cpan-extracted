#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# The release roll (0.04, plan_bowling 02). The marks, in order:
#
#   1  spin 0 is today's path: a table fixture with tx, ty and spin 0 is
#      bit-identical, whatever tx and ty say
#   2  a lateral roll deflects by u_lat T / 7 over the skid, and the skid lasts
#      (2/7) |u0| / (mu_s g): the closed forms plan_bowling/01 derives from the
#      engine's own sliding law, arithmetic and not the engine's own numbers
#   3  the deflection is zero once the ball rolls: the heading at the end of
#      the roll is the heading at its start
#   4  a roll along the line, whatever its size, is straight
#   5  refusals: bad_roll

use Physics::Balls;
use Physics::Balls::World;
use Presets;

plan tests => 14;

sub hexes { my ($row) = @_; return join ' ', map { unpack 'H*', pack 'd>', ($_ == 0 ? 0 : $_) } @$row }
sub segs_of { my ($o) = @_; return join "\n", map { my $id = $_; map { hexes($_) } @{ $o->segments->{$id} } } sort { $a <=> $b } keys %{ $o->segments } }

# ---- 1: spin 0 is today's path ----------------------------------------------------
{
	my ($f) = grep { $_->{id} eq 'cut' } Presets::fixtures();
	my $w = Presets::world_exact('pool');
	my $a = Physics::Balls->strike($w, layout => $f->{layout}, %{ $f->{shot} });
	my $b = Physics::Balls->strike($w, layout => $f->{layout}, %{ $f->{shot} }, tx => 123456, ty => -654321, spin => 0);
	is segs_of($b), segs_of($a), 'mark 1: spin 0 with any tx, ty is bit-identical to the shot without them';
}

# A long, wide open strip (the hooked ball rolls 110 m and ten metres left), the
# lane's constants, one ball of the lane's kind, released
# straight down it at 8 m/s with the roll of the flush pocket delivery: 0.40 of
# the speed along the line and 0.275 across it, to the left.
my $strip = Physics::Balls::World->new(L => 30, W => 200, R => 0.10795,
	walls => [[-15, -1, 15, -1], [15, -1, 15, 199], [15, 199, -15, 199], [-15, 199, -15, -1]], noses => [], gates => [],
	mu => { s => 0.09, r => 0.02, sp => 0.044 }, e => { bb => 0.55, c => 0.45, cf => 0.2, rc => 0.7 }, vmax => 9.5,
	kinds => [ { r => 0.10795, m => 6.804 } ]);
my ($g, $mus) = (9.81, 0.09);
my $power = 915;
my $speed = 0.3 + ($power / 1000) ** 2 * (9.5 - 0.3);
my ($rx, $ry) = (-0.275, 0.40);
my $rl = sqrt($rx * $rx + $ry * $ry);
my %shot = (ball => 0, dx => 0, dy => 1_000_000, power => $power, sx => 0, sy => 0,
	tx => int($rx / $rl * 1_000_000 + ($rx < 0 ? -0.5 : 0.5)), ty => int($ry / $rl * 1_000_000 + 0.5), spin => int($rl * 1000 + 0.5));

# ---- 2: the closed forms ------------------------------------------------------------
{
	my $out = Physics::Balls->strike($strip, layout => [ [0, 0, 20000, 0] ], %shot);
	ok !$out->error, 'mark 2: the hook plays' or diag $out->message;
	my $seg0 = $out->segments->{0}[0];
	# the release roll the engine built from the shot's integers, as the JavaScript does it
	my $tl = sqrt($shot{tx} ** 2 + $shot{ty} ** 2);
	my ($r0x, $r0y) = ($shot{spin} / 1000 * $speed * $shot{tx} / $tl, $shot{spin} / 1000 * $speed * $shot{ty} / $tl);
	my ($u0x, $u0y) = ($seg0->[4] - $r0x, $seg0->[5] - $r0y);
	my $u0 = sqrt($u0x * $u0x + $u0y * $u0y);
	my $T = (2 / 7) * $u0 / ($mus * $g);
	my ($roll) = grep { $_->[1] eq 'roll' } @{ $out->events };
	cmp_ok abs($seg0->[1] - $T) / $T, '<', 1e-12, sprintf('mark 2: the skid lasts (2/7) |u0| / (mu_s g) = %.6f s', $T);
	ok $roll && abs($roll->[0] - $T) / $T < 1e-12, 'mark 2: and the roll event is at its end';
	# the lateral deflection over the skid: -u_lat T / 7, u_lat the slip's component to the left of the line
	my $uLat = -$u0x;
	my $xEnd = $seg0->[2] + $seg0->[4] * $seg0->[1] + 0.5 * $seg0->[6] * $seg0->[1] ** 2;
	my $lat = $xEnd - $seg0->[2];
	my $closed = $uLat * $T / 7;
	cmp_ok abs($lat - $closed) / abs($closed), '<', 1e-9, sprintf('mark 2: the ball deflects u_lat T / 7 = %.4f m over the skid', $closed);
	cmp_ok abs($closed), '>', 0.3, 'mark 2: which is half a metre or so, a real hook';
	cmp_ok $xEnd, '<', 0, 'mark 2: and to the left, the way a right-hander\'s ball turns';
	# ---- 3: straight once rolling
	# rolling, the deceleration is along the velocity, so the segment is a line:
	# the cross product of the start velocity and the acceleration is rounding
	my $rolling = $out->segments->{0}[1];
	my ($vx, $vy, $ax, $ay) = @$rolling[4 .. 7];
	cmp_ok abs($vx * $ay - $vy * $ax) / (sqrt($vx * $vx + $vy * $vy) * sqrt($ax * $ax + $ay * $ay)), '<', 1e-12, 'mark 3: the rolling segment does not turn';
	is scalar(@{ $out->segments->{0} }), 2, 'mark 3: one skid, one roll, nothing else';
}

# ---- 4: a roll along the line is straight ------------------------------------------
{
	my $out = Physics::Balls->strike($strip, layout => [ [0, 0, 20000, 0] ], %shot, tx => 0, ty => 1_000_000, spin => 400);
	my ($r) = grep { $_->[0] == 0 } @{ $out->rest };
	is $r->[1], 0, 'mark 4: a roll along the line of the shot leaves the ball on its line';
	my $both = Physics::Balls->strike($strip, layout => [ [0, 0, 20000, 0] ], ball => 0, dx => 0, dy => 1_000_000, power => $power, sx => 0, sy => 160);
	is segs_of($out), segs_of($both), 'mark 4: and spin 400 along the line is the tip offset sy 160 (2.5 * 0.16 = 0.40), bit for bit';
}

# ---- 5: refusals ----------------------------------------------------------------------
{
	sub refused { my ($out, $label) = @_; ok $out->error && $out->code eq 'bad_roll', "mark 5: $label is refused as bad_roll" or diag($out->error ? $out->code : 'accepted') }
	refused(Physics::Balls->strike($strip, layout => [ [0, 0, 20000, 0] ], %shot, spin => 1001), 'spin 1001');
	refused(Physics::Balls->strike($strip, layout => [ [0, 0, 20000, 0] ], %shot, tx => 0, ty => 0), 'a roll with no direction');
	refused(Physics::Balls->strike($strip, layout => [ [0, 0, 20000, 0] ], %shot, tx => 1_000_001), 'tx over a million');
}
