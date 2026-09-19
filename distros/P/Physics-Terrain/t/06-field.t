#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# The field: generation, the queries, the carve, the sculpt ops, and the
# swept query at every speed. A one-cell wall is never crossed: every
# single-projectile weapon at full power at 256 angles inside a box of
# one-cell walls stays inside it, and across the fixtures the fastest thing
# in the air moved more than seven cells a tick, so the sweep was doing real
# work rather than being exercised at walking pace.

use Physics::Terrain;
use Fixtures;

plan tests => 9;

subtest 'generation' => sub {
	plan tests => 7;
	my $field = Physics::Terrain->new(seed => 7, teams => 2);
	is $field->width, 1280, '1280 wide';
	is $field->height, 640, '640 high';
	is $field->seed, 7, 'seed 7';
	my $solid = $field->count;
	ok $solid > 0.25 * 1280 * 640 && $solid < 0.6 * 1280 * 640, "between a quarter and six tenths ground ($solid cells)";
	is $field->body_count, 8, 'two teams of four';
	my $again = Physics::Terrain->new(seed => 7, teams => 2);
	is $again->mask, $field->mask, 'the same seed gives the same mask';
	isnt(Physics::Terrain->new(seed => 8, place => 'none')->mask, $field->mask, 'another seed another mask');
};

subtest 'solid' => sub {
	plan tests => 5;
	my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'flat', floor => 400 }, place => 'none');
	ok $field->solid(10, 400), 'the floor is ground';
	ok !$field->solid(10, 399), 'the air above it is not';
	ok !$field->solid(-1, 500), 'left of the field is air';
	ok !$field->solid(10, 640), 'below the field is air';
	is $field->surface_at(10, 0), 400, 'the surface is the floor';
};

subtest 'swept' => sub {
	plan tests => 6;
	my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'empty' }, place => 'none');
	$field->sculpt([['fill', 100, 0, 100, 639]]);
	my @r = $field->swept(10, 10, 300, 10);
	is_deeply \@r, [1, 100, 10, 99, 10], 'a horizontal segment stops at the wall, last free cell beside it';
	@r = $field->swept(10, 10, 90, 300);
	is_deeply \@r, [0, 90, 300, 90, 300], 'a segment that meets nothing ends where it ends';
	@r = $field->swept(99, 10, 101, 12);
	is $r[0], 1, 'a diagonal across the wall hits it';
	@r = $field->swept(100, 10, 100, 10);
	is_deeply \@r, [1, 100, 10, 100, 10], 'a segment starting in the wall hits at once';
	$field->sculpt([['clear', 100, 0, 100, 639]]);
	for my $k (0 .. 200) { $field->sculpt([['fill', 300 + $k, 300 - $k, 300 + $k, 300 - $k]]) }
	@r = $field->swept(321, 270, 331, 280);
	is $r[0], 1, 'a one-cell staircase is hit by a line through the corner between two of its cells';
	ok(($r[1] == 325 && $r[2] == 275) || ($r[1] == 326 && $r[2] == 274), "at one of the two cells that share the corner ($r[1],$r[2])");
};

subtest 'carve' => sub {
	plan tests => 4;
	my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'flat', floor => 300 }, place => 'none');
	my $before = $field->count;
	my $n = $field->carve(640, 300, 10);
	ok $n > 0, "cleared $n cells";
	is $field->count, $before - $n, 'the count says the same';
	is $field->carve(640, 300, 10), 0, 'carving the same hole again clears nothing';
	is $field->carve(640, 300, -3), 0, 'a negative radius clears nothing';
};

subtest 'sculpt' => sub {
	plan tests => 6;
	my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'empty' }, place => 'none');
	$field->sculpt([['fill', 10, 10, 19, 19]]);
	is $field->count, 100, 'fill';
	$field->sculpt([['clear', 10, 10, 14, 19]]);
	is $field->count, 50, 'clear';
	$field->sculpt([['clear', 0, 0, 1279, 639], ['slope', 100, 600, 200, 500]]);
	ok $field->solid(150, 550) && !$field->solid(150, 549), 'slope: on the line is ground, above it is air';
	ok $field->solid(200, 639) && !$field->solid(99, 639) && !$field->solid(201, 639), 'slope: only between its ends';
	$field->sculpt([['clear', 0, 0, 1279, 639], ['fill', 0, 0, 1279, 639], ['disc', 640, 320, 5]]);
	is 1280 * 640 - $field->count, 81, 'disc: the cell count of radius 5';
	$field->sculpt([['clear', 0, 0, 1279, 639], ['platform', 640, 300, 9, 18]]);
	is $field->count, 19 * 5, 'platform: a 19 by 5 slab';
};

subtest 'landing spots stand every body on ground with headroom' => sub {
	my @seeds = (1 .. 20);
	plan tests => scalar @seeds;
	for my $seed (@seeds) {
		my $field = Physics::Terrain->new(seed => $seed, teams => 4);
		my @bad;
		for my $b (@{ $field->bodies }) {
			my ($cx, $cy) = (int($b->{x} / 256), int($b->{y} / 256));
			my $ground = grep { $field->solid($cx - 4 + $_, $cy) } 0 .. 7;
			my $clear = 1;
			for my $dy (1 .. 12) { for my $dx (-4 .. 3) { $clear = 0 if $field->solid($cx + $dx, $cy - $dy) } }
			push @bad, "body $b->{index} at $cx,$cy ground=$ground clear=$clear" unless $ground && $clear;
		}
		is_deeply \@bad, [], "seed $seed: sixteen bodies on ground, boxes clear" or diag(join "\n", @bad);
	}
};

subtest 'a one-cell wall is never crossed at full power' => sub {
	plan tests => 2;
	my (@bad, $shots);
	for my $weapon (0, 1) {
		for (my $a = 0; $a < 4096; $a += 16) {
			my $field = Physics::Terrain->new(seed => 1, gen => { profile => 'empty' },
				sculpt => [['fill', 640, 0, 640, 639], ['fill', 0, 120, 1279, 120], ['fill', 0, 500, 1279, 500], ['fill', 200, 0, 200, 639], ['fill', 420, 300, 420, 300]],
				bodies => [[0, 420, 200]], wind => 0);
			$field->sculpt([['clear', 420, 300, 420, 300]]);
			my $out = $field->run_turn(0, [], { tick => 0, weapon => $weapon, angle => $a, power => 100 });
			$shots++;
			for my $c (@{ $out->{craters} }) {
				push @bad, "weapon $weapon at $a brads cratered at @$c beyond a wall" if $c->[0] > 640 || $c->[0] < 200 || $c->[1] < 120 || $c->[1] > 500;
			}
			push @bad, "weapon $weapon at $a brads left the box" if grep { $_->[1] eq 'lost' } @{ $out->{events} };
		}
	}
	is $shots, 512, '512 full-power shots';
	is_deeply \@bad, [], 'none escaped' or diag(join "\n", @bad[0 .. ($#bad < 5 ? $#bad : 5)]);
};

subtest 'the sweep is exercised at every speed' => sub {
	plan tests => 4;
	my %bucket = (slow => 0, mid => 0, fast => 0, over7 => 0);
	for my $fx (Fixtures::all()) {
		my $field = Fixtures::build($fx);
		my $out = $field->run_turn($fx->{active}, $fx->{inputs}, $fx->{shot});
		for my $list (grep { defined } @{ $out->{trace}{shots} }) {
			for my $i (1 .. $#$list) {
				my $v = sqrt(($list->[$i][1] - $list->[$i - 1][1]) ** 2 + ($list->[$i][2] - $list->[$i - 1][2]) ** 2) / 256;
				$bucket{ $v < 1 ? 'slow' : $v < 4 ? 'mid' : $v < 7 ? 'fast' : 'over7' }++;
			}
		}
	}
	ok $bucket{slow} > 0, "$bucket{slow} moves under a cell a tick";
	ok $bucket{mid} > 0, "$bucket{mid} moves from one to four cells a tick";
	ok $bucket{fast} > 0, "$bucket{fast} moves from four to seven";
	ok $bucket{over7} > 0, "$bucket{over7} moves over seven cells a tick";
};

subtest 'the weapons and the launch vector' => sub {
	plan tests => 6;
	my $w = Physics::Terrain->weapons;
	is scalar @$w, 5, 'five weapons';
	is_deeply [map { $_->{id} } @$w], [qw(bazooka grenade shotgun cluster dynamite)], 'in order';
	is_deeply [Physics::Terrain->launch(0, 0, 100)], [2000, 0], 'the bazooka at full power to the right';
	is_deeply [Physics::Terrain->launch(0, 1024, 50)], [0, -1000], 'straight up at half power';
	is_deeply [Physics::Terrain->launch(0, 2048, 100)], [-2000, 0], 'to the left';
	ok !eval { Physics::Terrain->launch(7, 0, 1); 1 }, 'no weapon 7';
};
