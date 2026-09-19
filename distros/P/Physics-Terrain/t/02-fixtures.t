#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# REGRESSION baselines, not correctness. Every fixture in t/fixtures was
# recorded by plan_crater/prototype/record.js, the JavaScript this engine was
# transliterated from, so these tests prove the C reproduces the prototype and
# nothing more. The hand-derived vectors that say the physics is right are in
# t/01-vectors.t.
#
# The contract is exact: the events identical in tick, kind, order and
# participants; the craters, the canonical input log, the shot, the wind, the
# tick counts, every trace row and the tick-hash ladder identical; the end
# state identical integer for integer. t/03-bitwise.t adds the digests.

use Physics::Terrain;
use Fixtures;

my @fixtures = Fixtures::all();
plan tests => scalar @fixtures;

for my $fx (@fixtures) {
	subtest $fx->{id} => sub {
		plan tests => 12;
		my $field = Fixtures::build($fx);
		my @start = map { [ $_->{seat}, int($_->{x} / 256), int($_->{y} / 256), $_->{hp} ] } @{ $field->bodies };
		is_deeply \@start, $fx->{start}, 'the cast starts where the prototype put it';
		my $out = $field->run_turn($fx->{active}, $fx->{inputs}, $fx->{shot});
		is $out->{error}, $fx->{error}, 'the same error, or none';
		is $out->{ticks}, $fx->{ticks}, "$fx->{ticks} ticks";
		is $out->{settledAt}, $fx->{settledAt}, 'settled on the same tick';
		is $out->{wind}, $fx->{wind}, "wind $fx->{wind}";
		is_deeply $out->{inputs}, $fx->{inputs}, 'the input log as recorded';
		is_deeply $out->{shot}, $fx->{shot}, 'the shot as recorded';
		is_deeply $out->{events}, $fx->{events}, scalar(@{ $fx->{events} }) . ' events, identical';
		is_deeply $out->{craters}, $fx->{craters}, scalar(@{ $fx->{craters} }) . ' craters, identical';
		is_deeply $out->{trace}, $fx->{trace}, 'every trace row identical';
		is_deeply $out->{hashes}, $fx->{hashes}, 'the tick-hash ladder identical';
		is_deeply $out->{end}, $fx->{end}, 'the end state identical';
	};
}
