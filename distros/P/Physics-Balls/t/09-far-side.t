#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

# REGRESSION: a wall or a gate has a far side. A ball whose centre is more than a
# radius beyond a wall's line is not touching that wall, and a ball more than a
# radius beyond a gate's line has either crossed it already or is on the far side
# of a ring of gates; in both cases the segment is skipped. Pool and snooker never
# meet the far side of anything (beyond a cushion there is only the frame, beyond
# a pocket gate only the pocket), so the 21 table fixtures in t/02 and t/03 cannot
# see the bound and this fixture, recorded by plan_minigolf/prototype/record.js on
# two course worlds, is the one that does. Without the gate bound the first stroke
# is holed at once from 400 mm beyond the rim; without the wall bound the last
# stroke bounces off a wall 1.3 m away on the far side of its line.
#
# The strokes are held to the same contract as t/02 and the same digest as t/03.

use Physics::Balls;
use Physics::Balls::World;
use Presets;
use Config;

my $fx = Presets::read_json(Presets::fixture_dir() . '/course/far-side.json');
my @strokes = @{ $fx->{strokes} };
plan tests => 2 + 5 * @strokes;

sub canon { my ($v) = @_; return $v == 0 ? 0 : $v }

sub digest_of {
	my ($segments) = @_;
	my $sha = Digest::SHA->new(256);
	for my $id (sort { $a <=> $b } keys %$segments) {
		for my $s (@{ $segments->{$id} }) {
			$sha->add(pack 'd>', canon($_)) for @$s;
		}
	}
	return $sha->hexdigest;
}

sub world_of {
	my ($g) = @_;
	my ($w, $hx) = ($g->{world}, $g->{hex});
	my $conv = sub {
		my ($rows, $hexrows) = @_;
		return [ map { my $i = $_; [ map { Presets::hex_to_nv($hexrows->[$i][$_]) } 0 .. $#{ $rows->[$i] } ] } 0 .. $#$rows ];
	};
	return Physics::Balls::World->new(
		L => Presets::hex_to_nv($hx->{L}), W => Presets::hex_to_nv($hx->{W}), R => Presets::hex_to_nv($hx->{R}),
		walls => $conv->($w->{walls}, $hx->{walls}),
		noses => $conv->($w->{noses}, $hx->{noses}),
		gates => $conv->($w->{gates}, $hx->{gates}),
		g => $w->{g}, vmax => $w->{vmax}, mu => $w->{mu}, e => $w->{e},
	);
}

my %world = map { $_ => world_of($fx->{geometry}{$_}) } keys %{ $fx->{geometry} };
my $wide = Presets::wide_doubles();

is scalar @{ $world{straight}->gates }, 16, 'the straight lane has a ring of sixteen gates round its cup';
ok $world{you}->walls->[0][1] == $world{you}->walls->[0][3] && @{ $world{you}->walls } >= 8, 'the U is a concave course whose first wall is its top';

for my $s (@strokes) {
	my $out = Physics::Balls->strike($world{ $s->{course} }, layout => $s->{layout}, %{ $s->{shot} });
	my $label = "$s->{course}/$s->{id}";
	ok !$out->error, "$label: the engine plays it" or diag($out->message);

	my ($settled, $recorded) = (Presets::settle_ties($out->events, 1e-6), Presets::settle_ties($s->{events}, 1e-6));
	my @mine = map { [ $_->[1], $_->[2], (defined $_->[3] ? $_->[3] : ()) ] } @$settled;
	my @theirs = map { [ $_->[1], $_->[2], (defined $_->[3] ? $_->[3] : ()) ] } @$recorded;
	my $times = 1;
	for my $i (0 .. $#theirs) {
		$times = 0 if !defined $settled->[$i] || abs($settled->[$i][0] - $recorded->[$i][0]) >= 1e-6;
	}
	ok $times && eq_array(\@mine, \@theirs), "$label: the events agree in kind, order, participants and time to 1e-6 s"
		or diag(explain { mine => $out->events, recorded => $s->{events} });

	is_deeply [ $out->rest, [ map { [ $_->[0], $_->[1] ] } @{ $out->holed } ] ],
		[ $s->{rest}, [ map { [ $_->[0], $_->[1] ] } @{ $s->{holed} } ] ], "$label: the rest layout and the holed list are identical";

	SKIP: {
		skip $wide, 1 if $wide;
		is $out->error ? 'ERROR' : digest_of($out->segments), $s->{segments_sha256}, "$label: the segments are bit-identical to the prototype's"
			or diag("on $Config{archname}, $Config{cc}");
	}

	my $e = $s->{expect};
	my @claims;
	push @claims, (@{ $out->holed } ? 1 : 0) == ($e->{holed} ? 1 : 0) ? () : ($e->{holed} ? 'not holed' : 'holed');
	if (defined $e->{first_wall}) {
		my ($first) = grep { $_->[1] eq 'wall' } @{ $out->events };
		push @claims, 'first wall ' . ($first ? $first->[3] : 'none') . ", not $e->{first_wall}" if !$first || $first->[3] != $e->{first_wall};
	}
	if (defined $e->{rest_y_below}) {
		my $y = $out->rest->[0] ? $out->rest->[0][2] / 100 : undef;
		push @claims, 'rested at y ' . (defined $y ? $y : 'nowhere') if !defined $y || $y >= $e->{rest_y_below};
	}
	is_deeply \@claims, [], "$label: $s->{title}";
}
