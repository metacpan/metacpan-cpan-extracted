#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

# The invariants, over seeded random shots from random layouts on both tables.
# There is no perft for a ball table; this is what stands in for one. Every
# number the engine produces must satisfy them whatever the shot:
#
#   - at rest no ball is outside the walls and no two overlap;
#   - the total energy per unit mass, v^2/2 + (r^2 + z^2)/5, never rises across
#     an event by more than one part in a million of what the strike put in;
#   - every shot terminates without the engine giving up;
#   - a ball's segments are contiguous in time except across a spell at rest
#     (a ball that stopped and was struck again), and continuous in position at
#     each boundary to within the engine's resting-contact correction, which
#     may move a ball that crept inside a neighbour back out by up to 0.1 mm.
#
# The randomness is sha256 of a fixed seed, so a failure replays.

use Physics::Balls;
use Presets;

my $N = $ENV{PB_RANDOM_SHOTS} || 300;
my $POS_TOL = 1e-4;    # metres: the resting-contact positional correction

my %world = map { $_ => Presets::world_built($_) } Presets::names();
my %desc = map { $_ => Presets::desc($_) } Presets::names();
my %balls = (pool => 16, snooker => 22);

plan tests => 2 * 4 + 4;

my $counter = 0;
sub word { my ($label) = @_; return unpack 'N', Digest::SHA::sha256("invariants:$label:" . $counter++) }
sub unit { return word($_[0]) / 4294967296 }

sub random_layout {
    my ($name, $n) = @_;
    my ($L, $W, $R) = ($desc{$name}{L}, $desc{$name}{W}, $desc{$name}{R});
    my @layout;
    for my $id (0 .. $n - 1) {
        my $tries = 0;
        while ($tries++ < 200) {
            my $x = $R + 0.002 + unit('x') * ($L - 2 * $R - 0.004);
            my $y = $R + 0.002 + unit('y') * ($W - 2 * $R - 0.004);
            my $ok = 1;
            for my $b (@layout) {
                my ($bx, $by) = ($b->[1] * 1e-5, $b->[2] * 1e-5);
                if (($x - $bx) ** 2 + ($y - $by) ** 2 < (2 * $R + 0.001) ** 2) { $ok = 0; last }
            }
            if ($ok) { push @layout, [ $id, int($x * 1e5 + 0.5), int($y * 1e5 + 0.5) ]; last }
        }
    }
    return \@layout;
}

sub random_shot {
    my $a = unit('a') * 6.283185307179586;
    my ($sx, $sy) = (unit('sx') - 0.5, unit('sy') - 0.5);
    my $l = sqrt($sx * $sx + $sy * $sy);
    if ($l > 0.5) { $sx *= 0.5 / $l; $sy *= 0.5 / $l }
    return (dx => int(cos($a) * 1_000_000), dy => int(sin($a) * 1_000_000),
            power => 50 + int(unit('p') * 951), sx => int($sx * 1000), sy => int($sy * 1000));
}

for my $name (Presets::names()) {
    my $world = $world{$name};
    my $R = $world->R;
    my (@geometry, @energy, @termination, @segments);
    my $max_rise = 0;
    for my $k (0 .. $N - 1) {
        my $n = 2 + int(unit('n') * ($balls{$name} - 1));
        my $layout = random_layout($name, $n);
        my $out = Physics::Balls->strike($world, layout => $layout, ball => 0, trace => 1, random_shot());
        my $label = "$name shot $k";
        if ($out->error) { push @termination, "$label: " . $out->message; next }
        for my $i (0 .. $#{ $out->rest }) {
            my ($id, $x, $y) = @{ $out->rest->[$i] };
            ($x, $y) = ($x * 1e-5, $y * 1e-5);
            push @geometry, "$label: ball $id outside the walls at $x, $y"
                if ($x < $R - 1e-6 || $x > $world->L - $R + 1e-6 || $y < $R - 1e-6 || $y > $world->W - $R + 1e-6)
                && !($x > -2 * $R && $x < $world->L + 2 * $R && $y > -2 * $R && $y < $world->W + 2 * $R);
            for my $j ($i + 1 .. $#{ $out->rest }) {
                my $d = sqrt(($x - $out->rest->[$j][1] * 1e-5) ** 2 + ($y - $out->rest->[$j][2] * 1e-5) ** 2);
                push @geometry, "$label: balls $id and $out->rest->[$j][0] overlap by " . (2 * $R - $d) * 1000 . ' mm' if $d < 2 * $R - 1e-6;
            }
        }
        my $e = $out->energy;
        for my $i (1 .. $#$e) {
            my $rise = $e->[$i] - $e->[$i - 1];
            $max_rise = $rise if $rise > $max_rise;
            push @energy, "$label: energy rose by $rise at event $i" if $rise > 1e-6 * $e->[0];
        }
        for my $id (keys %{ $out->segments }) {
            my $segs = $out->segments->{$id};
            for my $i (1 .. $#$segs) {
                my ($p, $q) = ($segs->[ $i - 1 ], $segs->[$i]);
                # a gap in time is allowed only after a segment that ended at rest:
                # the ball stopped, sat, and was struck again
                my $end_speed = sqrt(($p->[4] + $p->[6] * $p->[1]) ** 2 + ($p->[5] + $p->[7] * $p->[1]) ** 2);
                push @segments, "$label: ball $id segment $i starts at $q->[0], the last ended at " . ($p->[0] + $p->[1]) . " still moving at $end_speed m/s"
                    if abs($p->[0] + $p->[1] - $q->[0]) > 1e-9 && $end_speed > 2e-3;
                my $ex = $p->[2] + $p->[4] * $p->[1] + 0.5 * $p->[6] * $p->[1] * $p->[1];
                my $ey = $p->[3] + $p->[5] * $p->[1] + 0.5 * $p->[7] * $p->[1] * $p->[1];
                my $jump = sqrt(($ex - $q->[2]) ** 2 + ($ey - $q->[3]) ** 2);
                push @segments, "$label: ball $id jumps " . ($jump * 1000) . " mm between segments " . ($i - 1) . " and $i" if $jump > $POS_TOL;
            }
        }
    }
    is_deeply \@geometry, [], "$name: $N random shots, every ball at rest inside the walls and no two overlapping" or diag(join "\n", @geometry[0 .. 4]);
    is_deeply \@energy, [], "$name: energy never rose by more than a millionth of the strike (max rise $max_rise)" or diag(join "\n", @energy[0 .. 4]);
    is_deeply \@termination, [], "$name: every shot terminated" or diag(join "\n", @termination[0 .. 4]);
    is_deeply \@segments, [], "$name: segments contiguous in time and continuous in position to $POS_TOL m" or diag(join "\n", @segments[0 .. 4]);
}

# REGRESSION, from the phase 09 gate (16 Sep 2026): pool, bot ladder rung 3,
# game 68, shot 14. The cue ball sent the 14 into the 9; the pair, touching and
# not closing, crept inside each other under their differing decelerations (a
# touching pair closing slower than APPROACH is deliberately not an event) and
# stopped 1.08 mm overlapped, and the next strike refused the layout. The
# settle pass at the end of a shot sets a resting pair back to exactly 2R.
{
    my $world = $world{pool};
    my $R = $world->R;
    my $layout = [ [0, 208071, 119625], [14, 212075, 4458], [7, 209452, 15436], [8, 203624, 36901], [15, 149467, 123152],
                   [9, 218008, 5440], [11, 194460, 70602], [12, 207059, 95812], [13, 244669, 18778], [6, 232347, 36553], [10, 249667, 34405] ];
    my $out = Physics::Balls->strike($world, layout => $layout, ball => 0, dx => -969453, dy => -245275, power => 450, sx => 0, sy => 200);
    ok !$out->error, 'the gate\'s shot runs' or diag $out->message;
    my %at = map { $_->[0] => $_ } @{ $out->rest };
    my $d = sqrt(($at{14}[1] - $at{9}[1]) ** 2 + ($at{14}[2] - $at{9}[2]) ** 2) * 1e-5;
    ok $d >= 2 * $R - 1e-6, sprintf('REGRESSION: the 14 and the 9 rest %.3f mm apart, not inside each other (2R is %.3f)', $d * 1000, 2 * $R * 1000);
    my @overlap;
    for my $i (0 .. $#{ $out->rest }) {
        for my $j ($i + 1 .. $#{ $out->rest }) {
            my $dd = sqrt(($out->rest->[$i][1] - $out->rest->[$j][1]) ** 2 + ($out->rest->[$i][2] - $out->rest->[$j][2]) ** 2) * 1e-5;
            push @overlap, "$out->rest->[$i][0] and $out->rest->[$j][0]" if $dd < 2 * $R - 1e-6;
        }
    }
    is_deeply \@overlap, [], 'and no pair at rest overlaps';
    ok(scalar(grep { $_->[1] eq 'ball' && (($_->[2] == 14 && $_->[3] == 9) || ($_->[2] == 9 && $_->[3] == 14)) } @{ $out->events }), 'the 14 and the 9 did meet in the shot');
}
