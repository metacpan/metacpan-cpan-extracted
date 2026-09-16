#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# REGRESSION baselines, not correctness. Every fixture in t/fixtures was
# recorded by plan_pool_snooker/prototype/physics.js, the JavaScript this engine
# was transliterated from, so these tests prove the C reproduces the prototype
# within tolerance and nothing more. The four hand-derived vectors that say the
# physics is right are in t/01-vectors.t.
#
# The contract: the event list identical in kind, order and participants with
# times within 1e-6 s; every segment's eight numbers within 1e-9; the rest
# layout identical to the hundredth of a millimetre; the holed list identical.
# t/03-bitwise.t asks for more on top.

use Physics::Balls;
use Presets;

my @fixtures = Presets::fixtures();
plan tests => scalar @fixtures;

my %world = map { $_ => Presets::world_exact($_) } Presets::names();

for my $fx (@fixtures) {
	subtest "$fx->{table}/$fx->{id}" => sub {
		my $out = Physics::Balls->strike($world{ $fx->{table} },
			layout => $fx->{layout}, %{ $fx->{shot} });
		if ($out->error && $out->error ne ($fx->{error} // '')) {
			plan tests => 1;
			fail('the engine failed: ' . $out->message);
			return;
		}
		plan tests => 5;

		my @mine = @{ $out->events };
		my @theirs = @{ $fx->{events} };
		my @bad;
		push @bad, 'count ' . scalar(@mine) . ' vs ' . scalar(@theirs) if @mine != @theirs;
		for my $i (0 .. ($#mine < $#theirs ? $#mine : $#theirs)) {
			my ($m, $t) = ($mine[$i], $theirs[$i]);
			my $same = $m->[1] eq $t->[1] && $m->[2] == $t->[2]
				&& ((@$m < 4 && @$t < 4) || (defined $m->[3] && defined $t->[3] && $m->[3] == $t->[3]))
				&& abs($m->[0] - $t->[0]) < 1e-6;
			push @bad, "event $i: mine [@$m] theirs [@$t]" unless $same;
			last if @bad > 3;
		}
		is_deeply \@bad, [], 'the events agree in kind, order, participants and time to 1e-6 s'
			or diag(join "\n", @bad);

		is_deeply $out->rest, $fx->{rest}, 'the rest layout is identical to the hundredth of a millimetre';

		is_deeply [ map { [ $_->[0], $_->[1] ] } @{ $out->holed } ],
			[ map { [ $_->[0], $_->[1] ] } @{ $fx->{holed} } ], 'the same balls dropped in the same pockets';

		is_deeply [ sort { $a <=> $b } keys %{ $out->segments } ],
			[ sort { $a <=> $b } keys %{ $fx->{segments} } ], 'the same balls moved';

		my @seg_bad;
		for my $id (sort { $a <=> $b } keys %{ $fx->{segments} }) {
			my $m = $out->segments->{$id} || [];
			my $t = $fx->{segments}{$id};
			push @seg_bad, "ball $id: " . scalar(@$m) . ' segments vs ' . scalar(@$t) if @$m != @$t;
			for my $i (0 .. ($#$m < $#$t ? $#$m : $#$t)) {
				for my $k (0 .. 7) {
					if (abs($m->[$i][$k] - $t->[$i][$k]) >= 1e-9) {
						push @seg_bad, "ball $id segment $i field $k: $m->[$i][$k] vs $t->[$i][$k]";
						last;
					}
				}
				last if @seg_bad > 3;
			}
		}
		is_deeply \@seg_bad, [], 'every segment agrees to 1e-9' or diag(join "\n", @seg_bad);
	};
}
