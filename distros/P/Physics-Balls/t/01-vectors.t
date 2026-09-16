#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# The correctness vectors: numbers worked on paper, never read off the engine.
# Everything else in the suite is a regression baseline recorded from the
# prototype; these four are what say the physics is right.

use Physics::Balls;
use Presets;

plan tests => 4;

sub I { my ($m) = @_; return int($m * 1e5 + 0.5) }

sub seg_at_start {
	my ($segs, $t) = @_;
	for my $s (@$segs) { return $s if abs($s->[0] - $t) < 1e-12 }
	return;
}
sub seg_ending_at {
	my ($segs, $t) = @_;
	for my $s (@$segs) { return $s if abs($s->[0] + $s->[1] - $t) < 1e-12 }
	return;
}

subtest 'a head-on collision splits the speed (1-e)/2 and (1+e)/2' => sub {
	plan tests => 2;
	# Equal masses, restitution e, the struck ball at rest. The striker keeps
	# (1-e)/2 of its approach speed and the struck ball takes (1+e)/2: momentum
	# v = v1 + v2, restitution v2 - v1 = e v. Solve: v1 = (1-e)v/2, v2 = (1+e)v/2.
	my $d = Presets::desc('pool');
	my $world = Presets::world_built('pool');
	my $out = Physics::Balls->strike($world,
		layout => [ [0, I(0.6), I($d->{W} / 2)], [1, I(0.9), I($d->{W} / 2)] ],
		ball => 0, dx => 1_000_000, dy => 0, power => 600, sx => 0, sy => 400);
	ok !$out->error, 'the shot ran' or diag $out->message;
	my ($hit) = grep { $_->[1] eq 'ball' } @{ $out->events };
	my $before = seg_ending_at($out->segments->{0}, $hit->[0]);
	my $v = $before->[4] + $before->[6] * $before->[1];
	my $after0 = seg_at_start($out->segments->{0}, $hit->[0]);
	my $after1 = seg_at_start($out->segments->{1}, $hit->[0]);
	my $e = $d->{e}{bb};
	ok abs($after0->[4] - (1 - $e) / 2 * $v) < 1e-9 && abs($after1->[4] - (1 + $e) / 2 * $v) < 1e-9,
		"striker $after0->[4], struck $after1->[4], from v = $v with e = $e";
};

subtest 'a cushion with e = 1 and no friction reflects the angle exactly' => sub {
	plan tests => 2;
	my $d = Presets::desc('pool');
	my $world = Physics::Balls::World->from_table(Presets::table('pool'),
		mu => $d->{mu}, e => { bb => 0.95, c => 1, cf => 0, rc => 1 }, vmax => 8, g => 9.81);
	my $out = Physics::Balls->strike($world,
		layout => [ [0, I(0.8), I(0.4)] ],
		ball => 0, dx => 707107, dy => -707107, power => 500, sx => 0, sy => 400);
	ok !$out->error, 'the shot ran' or diag $out->message;
	my ($hit) = grep { $_->[1] eq 'wall' } @{ $out->events };
	my $before = seg_ending_at($out->segments->{0}, $hit->[0]);
	my $after = seg_at_start($out->segments->{0}, $hit->[0]);
	my $vxb = $before->[4] + $before->[6] * $before->[1];
	my $vyb = $before->[5] + $before->[7] * $before->[1];
	ok abs($after->[4] - $vxb) < 1e-9 && abs($after->[5] + $vyb) < 1e-9,
		"in ($vxb, $vyb) out ($after->[4], $after->[5])";
};

subtest 'a rolling ball travels v^2 / (2 mu_r g)' => sub {
	plan tests => 2;
	# Constant deceleration mu_r g from speed v: distance v^2 / (2 mu_r g). The
	# speed of a strike is 0.3 + p^2 (vmax - 0.3) with p = power / 1000. Read
	# from the last segment's own end, not the rounded rest position.
	my $d = Presets::desc('pool');
	my $world = Presets::world_built('pool');
	my $out = Physics::Balls->strike($world,
		layout => [ [0, I(0.3), I($d->{W} / 2)] ],
		ball => 0, dx => 1_000_000, dy => 0, power => 250, sx => 0, sy => 400);
	ok !$out->error, 'the shot ran' or diag $out->message;
	my $seg = $out->segments->{0}[-1];
	my $x_end = $seg->[2] + $seg->[4] * $seg->[1] + 0.5 * $seg->[6] * $seg->[1] * $seg->[1];
	my $v = 0.3 + 0.0625 * ($d->{vmax} - 0.3);
	my $expect = 0.3 + $v * $v / (2 * $d->{mu}{r} * $d->{g});
	ok abs($x_end - $expect) < 1e-9, "rolled to $x_end, expected $expect";
};

subtest 'a tip 2/5 R above centre rolls at once' => sub {
	plan tests => 2;
	# r0 = (5/2) sy v0, so sy = 0.4 gives r0 = v0 and no slip: one segment, no
	# roll event, the ball is rolling from the strike.
	my $d = Presets::desc('pool');
	my $world = Presets::world_built('pool');
	my $out = Physics::Balls->strike($world,
		layout => [ [0, I(0.3), I($d->{W} / 2)] ],
		ball => 0, dx => 1_000_000, dy => 0, power => 250, sx => 0, sy => 400);
	is scalar @{ $out->segments->{0} }, 1, 'one segment from strike to rest';
	is scalar(grep { $_->[1] eq 'roll' } @{ $out->events }), 0, 'and no slide-to-roll transition';
};
