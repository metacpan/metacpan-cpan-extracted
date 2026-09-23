#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();
use Math::BigRat ();
use Time::HiRes ();
use Config;

# The curve (0.03, plan_curling_bowls 01). The marks of that phase, in order:
#
#   1  curve zero is inert: every earlier fixture bit-identical through the v1
#      entry point as well as the v2 one (t/03 and t/09 prove the v2 path)
#   2  a rotation does no work: energy never rises, and |v| is preserved across
#      every turn
#   3  the rotation is the rotation: with p = 0 the turns are equal and after N
#      of them the heading is the exact Math::BigRat tangent-addition
#      composition, an expectation that is arithmetic and not the engine's own
#   4  a rolling ball stays rolling under a curve
#   5  the adjust prefix is identical, and the first segment after it differs
#   6  the adjust fires once, and one way
#   7  the C is the JavaScript: every curve fixture bit-identical
#   8  the overshoot is bounded: the law at a step's end over the law at its
#      start, across every step of every fixture, under 1.25
#   9  the budget holds, as a ceiling and not a timing assertion
#  10  the payload is sane: segments per delivery, recorded
#  11  refusals: bad_kind, bad_adjust, a size smaller than the struct, ABI 2
#
# The curve fixtures under t/fixtures/curve are REGRESSION baselines recorded
# by plan_curling_bowls/prototype/record.js from physics.js; the constants in
# them are fitted, not measured, and say so there.

use Physics::Balls;
use Physics::Balls::World;
use Presets;

my %fx = map { $_ => Presets::read_json(Presets::fixture_dir() . "/curve/$_.json") } qw/curling bowls/;

sub canon { my ($v) = @_; return $v == 0 ? 0 : $v }
sub digest_of {
	my ($segments) = @_;
	my $sha = Digest::SHA->new(256);
	for my $id (sort { $a <=> $b } keys %$segments) {
		for my $s (@{ $segments->{$id} }) { $sha->add(pack 'd>', canon($_)) for @$s }
	}
	return $sha->hexdigest;
}
sub hexes { my ($seg) = @_; return join ' ', map { unpack 'H*', pack 'd>', canon($_) } @$seg }
sub first_few { my @all = @_; return @all[0 .. ($#all < 4 ? $#all : 4)] }
sub world_of {
	my ($g) = @_;
	my ($w, $hx) = ($g->{world}, $g->{hex});
	my $conv = sub {
		my ($rows, $hexrows) = @_;
		return [ map { my $i = $_; [ map { Presets::hex_to_nv($hexrows->[$i][$_]) } 0 .. $#{ $rows->[$i] } ] } 0 .. $#$rows ];
	};
	return Physics::Balls::World->new(
		L => Presets::hex_to_nv($hx->{L}), W => Presets::hex_to_nv($hx->{W}), R => Presets::hex_to_nv($hx->{R}),
		walls => $conv->($w->{walls}, $hx->{walls}), noses => $conv->($w->{noses}, $hx->{noses}), gates => $conv->($w->{gates}, $hx->{gates}),
		g => $w->{g}, vmax => $w->{vmax}, mu => $w->{mu}, e => $w->{e}, (defined $w->{curve} ? (curve => $w->{curve}) : ()), (defined $w->{kinds} ? (kinds => $w->{kinds}) : ()),
	);
}
sub seg_end_v { my ($s) = @_; return ($s->[4] + $s->[6] * $s->[1], $s->[5] + $s->[7] * $s->[1]) }
sub heading_change {
	my ($segs) = @_;
	my ($ax, $ay) = ($segs->[0][4], $segs->[0][5]);
	my ($bx, $by) = ($segs->[-1][4], $segs->[-1][5]);
	my $al = sqrt($ax * $ax + $ay * $ay) || 1;
	my $bl = sqrt($bx * $bx + $by * $by) || 1;
	my $c = ($ax * $bx + $ay * $by) / ($al * $bl);
	$c = 1 if $c > 1; $c = -1 if $c < -1;
	return atan2(sqrt(1 - $c * $c), $c) * 180 / 3.14159265358979;
}

my %world = map { $_ => world_of($fx{$_}{geometry}) } keys %fx;
my @strokes = map { @{ $fx{$_}{strokes} } } qw/curling bowls/;
my %by_id = map { my $s = $_; ("$s->{course}/$s->{id}" => $s) } @strokes;
# marks 1, 2 and 7 compare against doubles recorded at 64 bits, and a build
# whose compiler holds a double wider than that between operations skips them
my $wide = Presets::wide_doubles();

plan tests => 6 * @strokes + 37;

# ---- 7: the C is the JavaScript, and each stroke does what its note says --------
my %played;
for my $s (@strokes) {
	my $label = "$s->{course}/$s->{id}";
	my $out = Physics::Balls->strike($world{ $s->{course} }, layout => $s->{layout}, %{ $s->{shot} });
	$played{$label} = $out;
	ok !$out->error, "$label: the engine plays it" or diag($out->message);

	my ($settled, $recorded) = (Presets::settle_ties($out->events, 1e-6), Presets::settle_ties($s->{events}, 1e-6));
	my @mine = map { [ $_->[1], $_->[2], (defined $_->[3] ? $_->[3] : ()) ] } @$settled;
	my @theirs = map { [ $_->[1], $_->[2], (defined $_->[3] ? $_->[3] : ()) ] } @$recorded;
	my $times = @mine == @theirs;
	for my $i (0 .. $#theirs) { $times = 0 if !defined $settled->[$i] || abs($settled->[$i][0] - $recorded->[$i][0]) >= 1e-6 }
	ok $times && eq_array(\@mine, \@theirs), "$label: the events agree in kind, order, participants and time to 1e-6 s"
		or diag(explain { mine => $out->events, recorded => $s->{events} });

	is_deeply [ $out->rest, [ map { [ $_->[0], $_->[1] ] } @{ $out->holed } ] ],
		[ $s->{rest}, [ map { [ $_->[0], $_->[1] ] } @{ $s->{holed} } ] ], "$label: the rest layout and the holed list are identical";

	SKIP: {
		skip $wide, 1 if $wide;
		is $out->error ? 'ERROR' : digest_of($out->segments), $s->{segments_sha256}, "$label: the segments are bit-identical to the prototype's (mark 7)"
			or diag("on $Config{archname}, $Config{cc}");
	}

	my $e = $s->{expect};
	my @claims;
	if (defined $e->{curved}) {
		my $segs = $out->segments->{ $e->{curved} } || [];
		my $turned = @$segs > 3 ? heading_change($segs) : 0;
		push @claims, "ball $e->{curved} turned $turned degrees over " . scalar(@$segs) . ' segments' if @$segs <= 3 || $turned < 1;
	}
	if ($e->{rest_near}) {
		my ($x, $y, $within) = @{ $e->{rest_near} };
		my ($r) = grep { $_->[0] == 0 } @{ $out->rest };
		my $d = $r ? sqrt(($r->[1] * 1e-5 - $x) ** 2 + ($r->[2] * 1e-5 - $y) ** 2) : 99;
		push @claims, sprintf('rested %.2f m from %s,%s', $d, $x, $y) if $d > $within;
	}
	if ($e->{holed_ids}) {
		push @claims, 'holed ' . join(',', map { $_->[0] } @{ $out->holed }) unless eq_array([ sort map { $_->[0] } @{ $out->holed } ], [ sort @{ $e->{holed_ids} } ]);
	}
	if ($e->{no_roll_event}) { push @claims, 'a roll event' if grep { $_->[1] eq 'roll' } @{ $out->events } }
	if ($e->{adjusted}) { push @claims, 'no adjust event' unless defined $out->adjusted_at }
	if (defined $e->{moved}) { push @claims, "ball $e->{moved} did not move" unless $out->segments->{ $e->{moved} } }
	is_deeply \@claims, [], "$label: $s->{title}";

	my $n = 0; $n += @{ $out->segments->{$_} } for keys %{ $out->segments };
	cmp_ok $n, '>', 0, "$label: $n segments in the payload, " . sprintf('%.1f', $out->t) . " s (mark 10)";
}

# ---- 1: curve zero is inert, through the v1 entry point too -----------------------
{
	my %table = map { $_ => Presets::world_exact($_) } Presets::names();
	my @bad;
	for my $f (Presets::fixtures()) {
		my $raw = $table{ $f->{table} }->engine->strike_v1($f->{layout}, $f->{shot});
		push @bad, "$f->{table}/$f->{id}" if digest_of($raw->{segments}) ne $f->{segments_sha256};
	}
	my $far = Presets::read_json(Presets::fixture_dir() . '/course/far-side.json');
	my %course = map { $_ => world_of($far->{geometry}{$_}) } keys %{ $far->{geometry} };
	for my $s (@{ $far->{strokes} }) {
		my $raw = $course{ $s->{course} }->engine->strike_v1($s->{layout}, $s->{shot});
		push @bad, "far-side/$s->{id}" if digest_of($raw->{segments}) ne $s->{segments_sha256};
	}
	SKIP: {
		skip $wide, 1 if $wide;
		is_deeply \@bad, [], 'mark 1: the 21 table fixtures and the course fixture are bit-identical through the ABI 1 entry point' or diag(join ', ', @bad);
	}
	my $f = (Presets::fixtures())[0];
	my $v1 = $table{ $f->{table} }->engine->strike_v1($f->{layout}, $f->{shot});
	my $v2 = $table{ $f->{table} }->engine->strike($f->{layout}, $f->{shot});
	is digest_of($v1->{segments}), digest_of($v2->{segments}), 'mark 1: the v1 wrapper and the v2 path agree on the same shot';
}

# ---- 2: a rotation does no work -----------------------------------------------------
{
	my (@energy, @speed);
	my $worst = 0;
	for my $s (@strokes) {
		my $out = Physics::Balls->strike($world{ $s->{course} }, layout => $s->{layout}, %{ $s->{shot} }, trace => 1);
		my $e = $out->energy;
		for my $i (1 .. $#$e) { push @energy, "$s->{course}/$s->{id}: rose by " . ($e->[$i] - $e->[$i - 1]) . " at event $i" if $e->[$i] - $e->[$i - 1] > 1e-6 * $e->[0] }
		my %event_at = map { sprintf('%.12f', $_->[0]) => 1 } @{ $out->events };
		for my $id (keys %{ $out->segments }) {
			my $segs = $out->segments->{$id};
			for my $i (1 .. $#$segs) {
				my ($p, $q) = ($segs->[ $i - 1 ], $segs->[$i]);
				next if $event_at{ sprintf('%.12f', $q->[0]) };
				my ($vx, $vy) = seg_end_v($p);
				my ($a, $b) = (sqrt($vx * $vx + $vy * $vy), sqrt($q->[4] * $q->[4] + $q->[5] * $q->[5]));
				my $rel = $a ? abs($a - $b) / $a : 0;
				$worst = $rel if $rel > $worst;
				push @speed, "$s->{course}/$s->{id}: ball $id turn $i: |v| $a then $b" if $rel > 4 * 2.220446049250313e-16;
			}
		}
	}
	is_deeply \@energy, [], 'mark 2: over the curve fixtures the energy never rises by more than a millionth of the strike' or diag(join "\n", first_few(@energy));
	SKIP: {
		skip $wide, 1 if $wide;
		is_deeply \@speed, [], "mark 2: |v| is preserved across every turn to within 4 ulps (worst $worst)" or diag(join "\n", first_few(@speed));
	}
}

# ---- 3: the rotation is the rotation ---------------------------------------------------
{
	# An empty box, p = 0 so the law is a constant k, the speed-fraction cap
	# switched off so every step is the heading cap exactly, a rolling start so
	# the heading changes only at turns. Each turn is a rotation by half-angle
	# tangent cap; after n of them the half-angle tangent is the tangent-addition
	# composition T(n+1) = (T(n) + cap) / (1 - T(n) cap), and the heading's
	# tangent is 2 T / (1 - T^2). Exact in Math::BigRat; the engine's vy / vx at
	# the start of the segment after the n-th turn must match to n ulps or so.
	my $cap = Math::BigRat->new('1/1000');
	my $world = Physics::Balls::World->new(L => 400, W => 400, R => 0.05,
		walls => [[-200, -200, 200, -200], [200, -200, 200, 200], [200, 200, -200, 200], [-200, 200, -200, -200]], noses => [], gates => [],
		mu => { s => 0.2, r => 0.02, sp => 0.044 }, vmax => 4,
		curve => { k => 0.01, vref => 1, vmin => 0.1, kmax => 1, p => 0, cap => 0.001, vfrac => 1e9 },
		kinds => [ { curve => 0 }, { curve => 1 } ]);
	my $out = Physics::Balls->strike($world, layout => [ [0, 0, 0, 1] ], ball => 0, dx => 1_000_000, dy => 0, power => 500, sx => 0, sy => 400);
	ok !$out->error, 'mark 3: the p = 0 run plays' or diag $out->message;
	my $segs = $out->segments->{0};
	my $turns = @$segs - 1;
	# each turn is two divisions and four products, so a few ulps of heading per
	# turn is the rounding of the rotation itself; the tolerance is four per turn
	my $T = Math::BigRat->new(0);
	my @bad;
	my $worst = 0;
	for my $n (1 .. $turns) {
		$T = ($T + $cap) / (1 - $T * $cap);
		my $tan = 2 * $T / (1 - $T * $T);
		my $mine = $segs->[$n][5] / $segs->[$n][4];
		my $err = abs(Math::BigRat->new($mine) - $tan)->numify;
		my $tol = (4 * $n + 8) * 2.220446049250313e-16 * abs($tan->numify);
		$worst = $err / $tol if $tol && $err / $tol > $worst;
		push @bad, "after turn $n: $mine, expected " . $tan->numify if $err > $tol;
	}
	cmp_ok $turns, '>', 50, "mark 3: $turns equal turns of half-angle tangent 1/1000";
	# the expectation is Math::BigRat's, so a failure names the version: below
	# 0.2613 a multiplication handed its second operand back changed
	is_deeply \@bad, [], sprintf('mark 3: the heading after every turn is the exact tangent-addition composition, to four ulps a turn (worst %.2f of the tolerance)', $worst)
		or diag(join("\n", first_few(@bad)) . "\nMath::BigRat $Math::BigRat::VERSION over Math::BigInt $Math::BigInt::VERSION on $Config{archname}");
	is scalar(grep { $_->[1] ne 'stop' } @{ $out->events }), 0, 'mark 3: a turn is not an event: the only event is the stop';
}

# ---- 4: a rolling ball stays rolling ---------------------------------------------------
{
	my $out = $played{'curling/draw'};
	is scalar(grep { $_->[1] eq 'roll' } @{ $out->events }), 0, 'mark 4: a stone delivered rolling with a curve never slides';
	is scalar(@{ $out->events }), 1, 'mark 4: and its only event is the stop';
}

# ---- 5: the adjust prefix is identical --------------------------------------------------
{
	# the swept fixture, and the same delivery played here with the adjust removed
	my $s = $by_id{'curling/draw-adjust'};
	my $swept = $played{'curling/draw-adjust'};
	my %plain_shot = %{ $s->{shot} };
	delete @plain_shot{qw/adjust adjust_at adjust_axis adjust_dir adjust_mu adjust_curve/};
	my $plain = Physics::Balls->strike($world{curling}, layout => $s->{layout}, %plain_shot);
	my $T = $swept->adjusted_at;
	ok defined $T && $T > 0, 'mark 5: the swept draw crossed the hog line at ' . (defined $T ? sprintf('%.3f s', $T) : 'never');
	# the crossing closes a segment in the swept run and not in the plain one,
	# so the swept prefix ends with a partial segment: every whole segment
	# before it is compared bit for bit, and the partial one against the start
	# of the plain segment it is the head of
	my @before_plain = grep { $_->[0] + $_->[1] <= $T + 1e-12 } @{ $plain->segments->{0} };
	my @before_swept = grep { $_->[0] + $_->[1] <= $T + 1e-12 } @{ $swept->segments->{0} };
	my $partial = pop @before_swept;
	my ($spanning) = grep { $_->[0] <= $T && $_->[0] + $_->[1] > $T } @{ $plain->segments->{0} };
	cmp_ok scalar @before_plain, '>', 10, 'mark 5: the prefix is many segments (' . scalar(@before_plain) . ')';
	is join("\n", map { hexes($_) } @before_swept), join("\n", map { hexes($_) } @before_plain), 'mark 5: every whole segment before the crossing is bit-identical with and without the adjust';
	is join(' ', map { unpack 'H*', pack 'd>', canon($partial->[$_]) } 0, 2 .. 7), join(' ', map { unpack 'H*', pack 'd>', canon($spanning->[$_]) } 0, 2 .. 7),
		'mark 5: and the segment cut by the crossing starts with the same eight doubles as the one it cuts';
	my ($after_plain) = grep { $_->[0] >= $T - 1e-12 } @{ $plain->segments->{0} };
	my ($after_swept) = grep { $_->[0] >= $T - 1e-12 } @{ $swept->segments->{0} };
	isnt hexes($after_swept), hexes($after_plain), 'mark 5: and the first segment after it differs';
	my ($rp) = grep { $_->[0] == 0 } @{ $plain->rest };
	my ($rs) = grep { $_->[0] == 0 } @{ $swept->rest };
	cmp_ok $rs->[2], '>', $rp->[2] + 100000, 'mark 5: the swept stone runs over a metre further (' . sprintf('%.2f m to %.2f m', $rp->[2] * 1e-5, $rs->[2] * 1e-5) . ')';
}

# ---- 6: the adjust fires once, and one way ----------------------------------------------
{
	my $box = Physics::Balls::World->new(L => 2, W => 2, R => 0.05,
		walls => [[0, 0, 2, 0], [2, 0, 2, 2], [2, 2, 0, 2], [0, 2, 0, 0]], noses => [], gates => [],
		mu => { s => 0.2, r => 0.02, sp => 0.044 }, e => { bb => 0.95, c => 0.9, cf => 0.2, rc => 0.7 }, vmax => 3);
	my %shot = (ball => 0, dx => 0, sx => 0, sy => 400, adjust => 1, adjust_at => 100000, adjust_axis => 1, adjust_mu => 500, adjust_curve => 1000);
	my $up = Physics::Balls->strike($box, layout => [ [0, 100000, 50000] ], %shot, dy => 1_000_000, power => 1000, adjust_dir => 1);
	ok !$up->error, 'mark 6: a ball bouncing up and down the box plays' or diag $up->message;
	my $crossings = 0;
	for my $s (@{ $up->segments->{0} }) {
		my $y0 = $s->[3]; my $y1 = $s->[3] + $s->[5] * $s->[1] + 0.5 * $s->[7] * $s->[1] * $s->[1];
		$crossings++ if ($y0 < 1 && $y1 >= 1) || ($y0 > 1 && $y1 <= 1);
	}
	cmp_ok $crossings, '>=', 3, "mark 6: it crosses the line $crossings times";
	is scalar(grep { $_->[1] eq 'adjust' } @{ $up->events }), 1, 'mark 6: and adjusts exactly once';
	my $down = Physics::Balls->strike($box, layout => [ [0, 100000, 150000] ], %shot, dy => -1_000_000, power => 514, adjust_dir => 1);
	ok !$down->error && $down->rest->[0][2] < 100000, 'mark 6: a ball crossing the line downward and stopping beyond it' or diag $down->message;
	is scalar(grep { $_->[1] eq 'adjust' } @{ $down->events }), 0, 'mark 6: does not adjust when the shot asked for the upward crossing';
	my $down2 = Physics::Balls->strike($box, layout => [ [0, 100000, 150000] ], %shot, dy => -1_000_000, power => 514, adjust_dir => -1);
	is scalar(grep { $_->[1] eq 'adjust' } @{ $down2->events }), 1, 'mark 6: and does when it asked for the downward one';
	my $beyond = Physics::Balls->strike($box, layout => [ [0, 100000, 150000] ], %shot, dy => 1_000_000, power => 514, adjust_dir => 1);
	is scalar(grep { $_->[1] eq 'adjust' } @{ $beyond->events }), 0, 'mark 6: a ball already beyond the line, moving away from it, never crosses it';
}

# ---- 8: the overshoot is bounded --------------------------------------------------------
{
	# over the segments a turn ended, of balls whose kind curves: a segment an
	# event ended is shorter than a step, and a ball with no curve never steps
	my $worst = 0; my $where = '';
	for my $s (@strokes) {
		my $w = $fx{ $s->{course} }{geometry}{world};
		my ($vmin, $p) = ($w->{curve}{vmin}, $w->{curve}{p});
		my %curves = map { $_->[0] => ($w->{kinds}[ $_->[3] || 0 ]{curve} != 0) } @{ $s->{layout} };
		my $out = $played{"$s->{course}/$s->{id}"};
		my %event_at = map { sprintf('%.12f', $_->[0]) => 1 } @{ $out->events };
		for my $id (grep { $curves{$_} } keys %{ $out->segments }) {
			my $segs = $out->segments->{$id};
			for my $i (0 .. $#$segs - 1) {
				my $seg = $segs->[$i];
				next if $event_at{ sprintf('%.12f', $seg->[0] + $seg->[1]) };
				my $a = sqrt($seg->[4] ** 2 + $seg->[5] ** 2);
				my ($ex, $ey) = seg_end_v($seg);
				my $b = sqrt($ex * $ex + $ey * $ey);
				$a = $vmin if $a < $vmin; $b = $vmin if $b < $vmin;
				my $ratio = ($a / $b) ** $p;
				if ($ratio > $worst) { $worst = $ratio; $where = "$s->{course}/$s->{id} ball $id segment $i" }
			}
		}
	}
	cmp_ok $worst, '<', 1.25, sprintf('mark 8: the law at a step\'s end over the law at its start is at most %.4f (%s), under 1.25', $worst, $where);
}

# ---- 9: the budget holds ----------------------------------------------------------------
{
	my %ms;
	for my $label (qw{curling/draw bowls/forehand curling/takeout}) {
		my $s = $by_id{$label};
		my $t0 = Time::HiRes::time();
		Physics::Balls->strike($world{ $s->{course} }, layout => $s->{layout}, %{ $s->{shot} }) for 1 .. 5;
		$ms{$label} = (Time::HiRes::time() - $t0) * 200;
	}
	diag(sprintf('mark 9: draw %.2f ms, forehand %.2f ms, takeout %.2f ms (ceilings 2, 2, 10 ms; asserted at 50 ms because smokers)', @ms{qw{curling/draw bowls/forehand curling/takeout}}));
	ok((grep { $_ < 50 } values %ms) == 3, 'mark 9: every delivery is under the 50 ms ceiling');
}

# ---- 11: refusals -------------------------------------------------------------------------
{
	my $c = $world{curling};
	my %shot = (ball => 0, dx => 0, dy => 1_000_000, power => 500, sx => 0, sy => 400);
	my $lay = sub { [ [0, 0, 1005900, @_] ] };
	sub refused { my ($out, $code, $label) = @_; ok $out->error && $out->code eq $code, "mark 11: $label is refused as $code" or diag($out->error ? $out->code : 'accepted') }
	refused(Physics::Balls->strike($c, layout => $lay->(3), %shot), 'bad_kind', 'kind 3 of 3');
	refused(Physics::Balls->strike($c, layout => $lay->(-1), %shot), 'bad_kind', 'kind -1');
	refused(Physics::Balls->strike($c, layout => $lay->(1.5), %shot), 'bad_kind', 'a fractional kind');
	refused(Physics::Balls->strike(Presets::world_built('pool'), layout => [ [0, 63500, 63500, 1] ], ball => 0, dx => 1_000_000, dy => 0, power => 500), 'bad_kind', 'kind 1 on a world with no kinds');
	refused(Physics::Balls->strike($c, layout => $lay->(1), %shot, adjust => 1, adjust_at => 1.5), 'bad_adjust', 'a fractional adjust line');
	refused(Physics::Balls->strike($c, layout => $lay->(1), %shot, adjust => 1, adjust_at => 3200700, adjust_axis => 2), 'bad_adjust', 'adjust axis 2');
	refused(Physics::Balls->strike($c, layout => $lay->(1), %shot, adjust => 1, adjust_at => 3200700, adjust_dir => 0), 'bad_adjust', 'adjust direction 0');
	refused(Physics::Balls->strike($c, layout => $lay->(1), %shot, adjust => 1, adjust_at => 3200700, adjust_mu => -1), 'bad_adjust', 'a negative friction factor');
	refused(Physics::Balls->strike($c, layout => $lay->(1), %shot, adjust => 1, adjust_at => 3200700, adjust_curve => 100001), 'bad_adjust', 'a curve factor over 100000');
	cmp_ok(Physics::Balls->abi_version, '>=', 2, 'mark 11: abi_version is at least 2, never exactly (the header\'s own rule)');
	ok $c->engine->bad_size_refused, 'mark 11: a v2 description and a v2 shot with a size smaller than the struct are refused';
	my $g = $fx{curling}{geometry}{world};
	my $tiny = Physics::Balls::World->new(L => $g->{L}, W => $g->{W}, R => $g->{R}, walls => $g->{walls}, noses => $g->{noses}, gates => $g->{gates},
		mu => $g->{mu}, e => $g->{e}, vmax => $g->{vmax}, kinds => $g->{kinds}, curve => { %{ $g->{curve} }, cap => 1e-9 });
	my $burnt = Physics::Balls->strike($tiny, layout => $lay->(1), %shot);
	is $burnt->error, 'turns', 'mark 11: a heading cap of a nanoradian runs the turn budget out and the engine says so rather than stopping quietly';
}
