#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# The table builder against the geometry the prototype's tables.js built for
# the same descriptions, to 1e-9 m. Bit-identity is not asked of it: cos and
# sin come from different libraries on the two sides, and the bitwise test
# starts from the recorded geometry for that reason.

use Physics::Balls;
use Presets;

plan tests => 2 * 7;

for my $name (Presets::names()) {
	my $table = Presets::table($name);
	my $g = Presets::geometry($name)->{world};
	is scalar @{ $table->walls }, 24, "$name: 24 walls";
	is scalar @{ $table->noses }, 24, "$name: 24 nose points";
	is scalar @{ $table->gates }, 6, "$name: 6 gates";
	is scalar @{ $table->pockets }, 6, "$name: 6 pockets";
	my @bad;
	for my $i (0 .. 23) {
		for my $k (0 .. 3) {
			push @bad, "wall $i field $k: $table->walls->[$i][$k] vs $g->{walls}[$i][$k]"
				if abs($table->walls->[$i][$k] - $g->{walls}[$i][$k]) > 1e-9;
		}
	}
	is_deeply \@bad, [], "$name: every wall matches tables.js to 1e-9" or diag(join "\n", @bad[0 .. 4]);
	@bad = ();
	for my $i (0 .. 5) {
		for my $k (0 .. 6) {
			push @bad, "gate $i field $k: $table->gates->[$i][$k] vs $g->{gates}[$i][$k]"
				if abs($table->gates->[$i][$k] - $g->{gates}[$i][$k]) > 1e-9;
		}
	}
	is_deeply \@bad, [], "$name: every gate matches to 1e-9" or diag(join "\n", @bad[0 .. 4]);
	my $out = Physics::Balls->strike(Presets::world_built($name),
		layout => [ [0, int($table->L * 0.25 * 1e5), int($table->W * 0.5 * 1e5)] ],
		ball => 0, dx => 1_000_000, dy => 0, power => 300, sx => 0, sy => 0);
	ok !$out->error && $out->t > 0, "$name: a world built from the table plays a shot";
}
