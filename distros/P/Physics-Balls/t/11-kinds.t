#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test2::Bundle::Numerical;
use Config;

# Ball kinds (0.04, plan_bowling 02). The marks, in order:
#
#   1  a world with no kinds is the old world exactly, and a world whose kinds
#      are all the default (R, mass 1, mu 1, rs R, vfall 0) replays a table
#      fixture bit-identically through rows that name the kind
#   2  the C is the JavaScript: every lane fixture recorded by
#      plan_bowling/prototype/record.js from the forked physics.js is
#      reproduced here, events, rest, holed, down, peak and segments
#   3  momentum: a head-on hit between a ball and a pin at e_bb 0.55 and the
#      4.29:1 mass ratio leaves the striker (m1 - e m2)/(m1 + m2) of its speed
#      and gives the struck body m1 (1 + e)/(m1 + m2), the closed forms worked
#      on paper and not read back from the engine
#   4  the peak is the peak: a struck pin's peak is its speed after the hit, the
#      ball's is its release speed
#   5  down: a pin past vfall leaves play with a down event and a down row, in
#      neither rest nor holed; a pin nudged below it stands where it stands
#   6  the sweep radius reaches a pin's own kind and not the ball
#   7  refusals: a kind's r, m, mu, rs and vfall are validated; overlap uses
#      the reach of the two kinds; the ABI version is 3
#
# The lane fixtures under t/fixtures/lane are REGRESSION baselines; the
# constants in them are house choices plan_bowling/01 decided and say so.
#
# Mark 2 is read in ulps of a double and not in bits, for two reasons a smoker
# found. The fixtures carry each number as the shortest decimal that names its
# double, which a long double perl parses to a long double a few bits off the
# double the engine holds, and prints differently again; and a compiler the
# prototype was never recorded on may order a sum its own way and land one ulp
# away, which the collisions after it carry along. Both are differences below
# the fifteenth digit. So the comparison is double's, whatever this perl's NV
# is, and the worst distance seen is in the test's own name: a smoke report
# then says how close to the tolerance the platform ran. The bit-for-bit
# target lives in t/03-bitwise.t, over the table fixtures.

use Physics::Balls;
use Physics::Balls::World;
use Presets;

my $dir = Presets::fixture_dir() . '/lane';
my $lane = Presets::read_json("$dir/world.json");
opendir my $dh, $dir or die "$dir: $!";
my @files = sort grep { /\.json\z/ && $_ ne 'world.json' } readdir $dh;
closedir $dh;
my @fx = map { Presets::read_json("$dir/$_") } @files;

plan tests => 4 * @fx + 33;

sub hexes { my ($row) = @_; return join ' ', map { unpack 'H*', pack 'd>', ($_ == 0 ? 0 : $_) } @$row }

# how far apart two recorded numbers are, counted in ulps of a double: the
# perl's own epsilon is not the measure, because the numbers being compared
# came out of a double and went into the fixture as one
use constant DBL_EPSILON => 2 ** -52;
use constant ULPS => 64;
sub ulps {
	my ($a, $b) = @_;
	return 0 if $a == $b;
	my $max = abs($a) > abs($b) ? abs($a) : abs($b);
	return $max > 0 ? abs($a - $b) / ($max * DBL_EPSILON) : 0;
}
# a failing lane has hundreds of differing numbers and a smoke report has to
# carry them: the count is the assertion, the first five are the diagnosis
sub first_few { my @all = @_; return @all[0 .. ($#all < 4 ? $#all : 4)] }
# an integer is an integer on every platform; a double is read in ulps
sub same {
	my ($a, $b) = @_;
	return !defined $a && !defined $b unless defined $a && defined $b;
	return "$a" eq "$b" if $a =~ /\A-?[0-9]+\z/ && $b =~ /\A-?[0-9]+\z/;
	return ulps($a, $b) <= ULPS;
}
sub lane_world {
	my (%over) = @_;
	my $w = $lane->{world};
	return Physics::Balls::World->new(
		L => $w->{L}, W => $w->{W}, R => $w->{R}, g => $w->{g}, vmax => $w->{vmax}, mu => $w->{mu}, e => $w->{e},
		walls => $w->{walls}, noses => $w->{noses}, gates => $w->{gates}, kinds => $w->{kinds}, %over,
	);
}
my $world = lane_world();
# and a build whose compiler holds a double wider than 64 bits between
# operations is off by hundreds of ulps after the first collision: mark 2 skips
my $wide = Presets::wide_doubles();

# ---- 2: the C is the JavaScript ---------------------------------------------------------
for my $f (@fx) {
	my $label = "lane/$f->{id}";
	my $out = Physics::Balls->strike($world, layout => $f->{layout}, %{ $f->{shot} });
	ok !$out->error, "$label: the engine plays it (" . scalar(@{ $out->events }) . ' events)' or diag($out->message);

	SKIP: {
	skip $wide, 3 if $wide;
	my @mine = @{ Presets::settle_ties($out->events, 1e-9) };
	my @theirs = @{ Presets::settle_ties($f->{events}, 1e-9) };
	my @bad;
	my $worst = 0;
	push @bad, 'count ' . scalar(@mine) . ' vs ' . scalar(@theirs) if @mine != @theirs;
	for my $i (0 .. ($#mine < $#theirs ? $#mine : $#theirs)) {
		my ($m, $t) = ($mine[$i], $theirs[$i]);
		my $u = ulps($m->[0], $t->[0]);
		$worst = $u if $u > $worst;
		push @bad, "event $i: mine [@$m] theirs [@$t]"
			unless $m->[1] eq $t->[1] && same($m->[2], $t->[2]) && same($m->[3], $t->[3]) && $u <= ULPS;
	}
	is_deeply \@bad, [],
		sprintf('%s: the same events between the same bodies in the same order, their times to %d ulps (worst %.1f)', $label, ULPS, $worst)
		or diag(join("\n", first_few(@bad)) . "\non $Config{archname}, $Config{cc}");

	# the prototype's rest rows carry the kind; the dist's are [id, x, y], the
	# 0.03 contract. rest and down carry hundredths of a millimetre, integers;
	# the time in holed and down, and every peak, is a double
	my @state;
	my $rows = sub {
		my ($what, $mine, $theirs, $n) = @_;
		if (@$mine != @$theirs) {
			push @state, "$what: " . scalar(@$mine) . ' rows vs ' . scalar(@$theirs);
			return;
		}
		for my $i (0 .. $#$theirs) {
			my ($m, $t) = ($mine->[$i], $theirs->[$i]);
			push @state, "$what $i: [@{[ @$m[0 .. $n] ]}] vs [@{[ @$t[0 .. $n] ]}]" if grep { !same($m->[$_], $t->[$_]) } 0 .. $n;
		}
	};
	$rows->('rest', $out->rest, $f->{rest}, 2);
	$rows->('holed', $out->holed, $f->{holed}, 2);
	$rows->('down', $out->down, $f->{down}, 3);
	my $peak = $out->peak;
	push @state, 'peak: ' . scalar(keys %$peak) . ' bodies vs ' . scalar(keys %{ $f->{peak} }) if keys %$peak != keys %{ $f->{peak} };
	for my $id (sort { $a <=> $b } keys %{ $f->{peak} }) {
		push @state, "peak $id: " . (defined $peak->{$id} ? $peak->{$id} : 'none') . " vs $f->{peak}{$id}" unless same($peak->{$id}, $f->{peak}{$id});
	}
	is_deeply \@state, [], "$label: rest, holed, down and peak are the prototype's" or diag(join("\n", first_few(@state)) . "\non $Config{archname}, $Config{cc}");

	my @seg;
	my ($n, $worst_seg) = (0, 0);
	my $segments = $out->segments;
	push @seg, 'balls ' . join(' ', sort { $a <=> $b } keys %$segments) . ' moved, not ' . join(' ', sort { $a <=> $b } keys %{ $f->{segments} })
		if join(' ', sort { $a <=> $b } keys %$segments) ne join(' ', sort { $a <=> $b } keys %{ $f->{segments} });
	for my $id (sort { $a <=> $b } keys %{ $f->{segments} }) {
		my ($m, $t) = ($segments->{$id} || [], $f->{segments}{$id});
		$n += @$t;
		if (@$m != @$t) {
			push @seg, "ball $id: " . scalar(@$m) . ' segments vs ' . scalar(@$t);
			next;
		}
		for my $i (0 .. $#$t) {
			for my $k (0 .. 7) {
				my $u = ulps($m->[$i][$k], $t->[$i][$k]);
				$worst_seg = $u if $u > $worst_seg;
				push @seg, sprintf('ball %d segment %d field %d: %s vs %s (%.1f ulps)', $id, $i, $k, $m->[$i][$k], $t->[$i][$k], $u) if $u > ULPS;
			}
		}
	}
	is_deeply \@seg, [],
		sprintf('%s: the segments are the prototype\'s to %d ulps (%d segments, worst %.1f)', $label, ULPS, $n, $worst_seg)
		or diag(join("\n", first_few(@seg)) . "\non $Config{archname}, $Config{cc}");
	}
}

# ---- 1: the default kind is the old world ---------------------------------------------------
{
	my ($f) = grep { $_->{id} eq 'break' } Presets::fixtures();
	my $plain = Presets::world_exact('pool');
	my $kinds = Physics::Balls::World->new(%{ $plain->description }, kinds => [ { r => $plain->R, m => 1, mu => 1, rs => $plain->R, vfall => 0 }, { r => $plain->R, m => 1, mu => 1 } ]);
	# never my $a or my $b in scope of a sort: the sort block would compare these
	my $bare = Physics::Balls->strike($plain, layout => $f->{layout}, %{ $f->{shot} });
	my $kinded = Physics::Balls->strike($kinds, layout => [ map { [ @$_, $_->[0] % 2 ] } @{ $f->{layout} } ], %{ $f->{shot} });
	my $seg = sub { my ($o) = @_; return join "\n", map { my $id = $_; map { hexes($_) } @{ $o->segments->{$id} } } sort { $a <=> $b } keys %{ $o->segments } };
	is $seg->($kinded), $seg->($bare), 'mark 1: the pool break through two default kinds, rows naming them, is bit-identical to the world with none';
	is_deeply $kinded->rest, $bare->rest, 'mark 1: and rests in the same places';
	is scalar(grep { @$_ == 3 } @{ $kinded->rest }), scalar(@{ $kinded->rest }), 'mark 1: a rest row is [id, x, y] whatever its layout row carried, the 0.03 contract';
	ok !exists $bare->to_payload->{down} && !exists $bare->to_payload->{peak} && $bare->to_payload->{engine} == 1, 'mark 1: a pool payload carries no down and no peak: it is the payload it always was';
	my $lane_out = Physics::Balls->strike($world, layout => $fx[0]{layout}, %{ $fx[0]{shot} });
	ok exists $lane_out->to_payload->{down} && exists $lane_out->to_payload->{peak}, 'mark 1: a lane payload carries both';
	ok $lane_out->kinded && !$bare->kinded, 'mark 1: because the lane is kinded and the table is not';
}

# ---- 3: momentum, on paper ---------------------------------------------------------------------
# An open box, a ball of mass 6.804 rolling (sy 400, so the roll is the velocity
# and there is no skid) dead at a pin of mass 1.588 with e_bb 0.55. The speed
# at impact is read from the ball's segment; the split is the closed form.
my $box = Physics::Balls::World->new(L => 4, W => 4, R => 0.10795,
	walls => [[0, 0, 4, 0], [4, 0, 4, 4], [4, 4, 0, 4], [0, 4, 0, 0]], noses => [], gates => [],
	mu => { s => 0.09, r => 0.02, sp => 0.044 }, e => { bb => 0.55, c => 0.45, cf => 0.2, rc => 0.7 }, vmax => 9.5,
	kinds => [ { r => 0.10795, m => 6.804 }, { r => 0.06053, m => 1.588, mu => 6, vfall => 0.25 } ]);
my %roll = (ball => 0, dx => 1_000_000, dy => 0, power => 600, sx => 0, sy => 400);
{
	my $out = Physics::Balls->strike($box, layout => [ [0, 50000, 200000, 0], [1, 200000, 200000, 1] ], %roll);
	ok !$out->error, 'mark 3: the head-on hit plays' or diag $out->message;
	my ($hit) = grep { $_->[1] eq 'ball' } @{ $out->events };
	my ($before) = grep { abs($_->[0] + $_->[1] - $hit->[0]) < 1e-12 } @{ $out->segments->{0} };
	my ($after0) = grep { abs($_->[0] - $hit->[0]) < 1e-12 } @{ $out->segments->{0} };
	my ($after1) = grep { abs($_->[0] - $hit->[0]) < 1e-12 } @{ $out->segments->{1} };
	my $v = $before->[4] + $before->[6] * $before->[1];
	my ($m1, $m2, $e) = (6.804, 1.588, 0.55);
	my $keep = ($m1 - $e * $m2) / ($m1 + $m2);      # 0.70556, on paper
	my $give = $m1 * (1 + $e) / ($m1 + $m2);        # 1.25688, on paper
	within_tol $after0->[4], $keep * $v, sprintf('mark 3: the ball keeps (m1 - e m2)/(m1 + m2) = %.5f of %.3f m/s', $keep, $v), 1e-9;
	within_tol $after1->[4], $give * $v, sprintf('mark 3: the pin takes m1 (1 + e)/(m1 + m2) = %.5f of it', $give), 1e-9;
	within_tol $m1 * $after0->[4] + $m2 * $after1->[4], $m1 * $v, 'mark 3: momentum is conserved', 1e-9;
	is_gt $after0->[4], 0, 'mark 3: the ball carries through, which at equal mass it would not (it would keep 0.225)';
	# ---- 4: the peak is the peak
	within_tol $out->peak_of(1), $after1->[4], 'mark 4: the pin\'s peak is its speed after the hit', 1e-12;
	my $release = 0.3 + 0.36 * (9.5 - 0.3);
	within_tol $out->peak_of(0), $release, 'mark 4: the ball\'s peak is its release speed', 1e-12;
	# ---- 5: down
	ok $out->downed(1), 'mark 5: the pin, past 0.25 m/s, went down';
	ok !(grep { $_->[0] == 1 } @{ $out->rest }) && !$out->potted(1), 'mark 5: and is in neither rest nor holed';
	is scalar(grep { $_->[1] eq 'down' && $_->[2] == 1 } @{ $out->events }), 1, 'mark 5: with one down event';
	ok((grep { $_->[0] == 0 } @{ $out->rest }), 'mark 5: the ball rests');
	my $d = $out->downed(1);
	my $last = $out->segments->{1}[-1];
	within_tol $d->[1] * 1e-5, $last->[2] + $last->[4] * $last->[1] + 0.5 * $last->[6] * $last->[1] ** 2,
		'mark 5: the down row is where its last segment ends', 1e-5;
}
{
	# the slowest ball there is (power 0 is 0.3 m/s) glancing off a pin set
	# 0.15 m to the side of its line, so the pin takes 0.45 of the closing speed
	# times 1.257, about 0.17 m/s, below 0.25: it moves a little and stands
	my $out = Physics::Balls->strike($box, layout => [ [0, 50000, 200000, 0], [1, 60000, 215000, 1] ], %roll, power => 0);
	ok !$out->error && !$out->downed(1), 'mark 5: a pin nudged at ' . sprintf('%.3f', $out->peak_of(1)) . ' m/s, below 0.25, is not down' or diag $out->message;
	my ($r) = grep { $_->[0] == 1 } @{ $out->rest };
	ok $r && ($r->[1] != 60000 || $r->[2] != 215000), 'mark 5: it stands where it was pushed to, ' . ($r ? sprintf('%.1f mm off its spot', sqrt(($r->[1] - 60000) ** 2 + ($r->[2] - 215000) ** 2) / 100) : 'gone');
	is_gt $out->peak_of(1), 0, 'mark 5: though it did move';
}

# ---- 6: the sweep radius ---------------------------------------------------------------------
{
	# pins of kind 1 reach each other at 2 rs = 0.30 m but the ball at r + r_pin.
	# Pin A is hit dead by the ball; pin B sits beside A's path offset by 0.25 m,
	# between 2 r (0.121) and 2 rs (0.30), so A sweeps it; pin C sits beside the
	# ball's path at the same offset, more than r_ball + r_pin (0.168), so the
	# ball passes it.
	my $sweep = Physics::Balls::World->new(%{ $box->description }, kinds => [ { r => 0.10795, m => 6.804 }, { r => 0.06053, rs => 0.15, m => 1.588, mu => 6, vfall => 0.25 } ]);
	my $out = Physics::Balls->strike($sweep, layout => [ [0, 50000, 200000, 0], [1, 200000, 200000, 1], [2, 260000, 225000, 1], [3, 120000, 225000, 1] ], %roll);
	ok !$out->error, 'mark 6: the sweep layout plays' or diag $out->message;
	ok((grep { $_->[1] eq 'ball' && (($_->[2] == 1 && $_->[3] == 2) || ($_->[2] == 2 && $_->[3] == 1)) } @{ $out->events }), 'mark 6: pin 1 reaches pin 2 at the sweep radius');
	ok !(grep { $_->[1] eq 'ball' && (($_->[2] == 0 && $_->[3] == 3) || ($_->[2] == 3 && $_->[3] == 0)) } @{ $out->events }), 'mark 6: the ball passes pin 3 at the same offset: the sweep is for pins only';
	my $err = Physics::Balls->strike($sweep, layout => [ [0, 50000, 200000, 0], [1, 200000, 200000, 1], [2, 220000, 200000, 1] ], %roll);
	ok $err->error && $err->code eq 'overlap', 'mark 7: two pins 0.20 m apart, inside 2 rs, are an overlap';
	my $ok = Physics::Balls->strike($sweep, layout => [ [0, 50000, 200000, 0], [1, 200000, 200000, 1], [2, 230000, 200000, 1] ], %roll);
	ok !$ok->error, 'mark 7: at 0.30 m they touch and are accepted';
}

# ---- 7: refusals -----------------------------------------------------------------------------
{
	for my $bad ([ r => -1 ], [ m => 0 ], [ mu => 'x' ], [ rs => -0.1 ], [ vfall => -1 ]) {
		ok !eval { Physics::Balls::World->new(%{ $box->description }, kinds => [ { @$bad } ]); 1 }, "mark 7: a kind with $bad->[0] $bad->[1] is refused";
	}
	ok(Physics::Balls->abi_version >= 3, 'mark 7: abi_version is at least 3 (the header says >=, never ==; 0.07 made it 4)');
	ok $box->engine->bad_size_refused, 'mark 7: a v2 description and a v2 shot with a size smaller than the struct are still refused';
}
