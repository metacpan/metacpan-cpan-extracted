#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Physics::Balls;
use Physics::Balls::World;
use Presets;

# ABI 4 (0.07, plan_air_hockey 02a): advance, the world run a fixed time from
# rows that carry a velocity. The fixtures under t/fixtures/rink were recorded
# by the JavaScript twin (plan_air_hockey/prototype/physics.js, record.js) with
# every double as sixteen hex digits, so -0 survives and no decimal is parsed;
# the integer state chain must match on every platform, the doubles bit for
# bit where the compiler rounds every operation to a double.

my $dir = Presets::fixture_dir() . '/rink';
my $wide = Presets::wide_doubles();

# a value from a hexified fixture: an integer is itself, a {hex} is a double
sub val { my ($v) = @_; return ref $v eq 'HASH' ? Presets::hex_to_nv($v->{hex}) : $v }
sub hexof { my ($v) = @_; return unpack 'H*', pack 'd>', $v }
# a recorded double: a {hex} (the segments), a bare sixteen-digit string (the
# times, which record.js writes with H.hex directly), or an integer
sub hexval { my ($v) = @_; return ref $v eq 'HASH' ? $v->{hex} : $v =~ /\A[0-9a-f]{16}\z/ ? $v : hexof($v) }
sub unhex_deep {
	my ($v) = @_;
	return [ map { unhex_deep($_) } @$v ] if ref $v eq 'ARRAY';
	return Presets::hex_to_nv($v->{hex}) if ref $v eq 'HASH' && exists $v->{hex} && keys %$v == 1;
	return { map { $_ => unhex_deep($v->{$_}) } keys %$v } if ref $v eq 'HASH';
	return $v;
}
sub world_from {
	my ($w) = @_;
	my $d = unhex_deep($w);
	return Physics::Balls::World->new(map { $_ => $d->{$_} } qw/L W R g vmax mu e kinds walls noses gates/);
}

my $rink = Presets::read_json("$dir/rink.json");
my $world = world_from($rink->{world});
my @tickfiles = map { "$dir/rink-tick-$_.json" } 1 .. 3;
my $frictionless = Physics::Balls::World->new(L => 2, W => 1, R => 0.0625, g => 9.81, mu => { s => 0, r => 0, sp => 0.044 },
	e => { bb => 0.9, c => 0.85, cf => 0, rc => 1 }, vmax => 8, kinds => [ { r => 0.0625, m => 1, mu => 1, follow => 0 } ],
	walls => [ [1, 0, 1, 2] ], noses => [], gates => []);

# ---- 1: the twin fixtures, hex to hex ------------------------------------------------------
subtest 'mark 1: three recorded rallies, 120 ticks each, the state chain and every double' => sub {
	plan tests => 3 * 4;
	for my $file (@tickfiles) {
		my $fx = Presets::read_json($file);
		my $w = world_from($fx->{world});
		my ($ticks, $bad_state, $bad_events, $bad_segs, $bad_t) = (0, 0, 0, 0, 0);
		for my $tk (@{ $fx->{ticks} }) {
			my $out = $w->engine->advance($tk->{rows}, { t => $tk->{dt} });
			$ticks++;
			$bad_state++ unless join('|', map { join ',', @$_ } @{ $out->{state} }) eq join('|', map { join ',', @$_ } @{ $tk->{state} });
			my $mine = join ';', map { join(',', hexof($_->[0]), @$_[1 .. $#$_]) } @{ $out->{events} };
			my $theirs = join ';', map { join(',', hexval($_->[0]), @$_[1 .. $#$_]) } @{ $tk->{events} };
			$bad_events++ unless $mine eq $theirs;
			my $m = join ';', map { my $id = $_; map { join ',', map { hexof($_) } @$_ } @{ $out->{segments}{$id} } } sort { $a <=> $b } keys %{ $out->{segments} };
			my $t = join ';', map { my $id = $_; map { join ',', map { hexval($_) } @$_ } @{ $tk->{segments}{$id} } } sort { $a <=> $b } keys %{ $tk->{segments} };
			$bad_segs++ unless $m eq $t;
			$bad_t++ unless hexof($out->{t}) eq hexval($tk->{t}) && $out->{n} == $tk->{n} && !defined $out->{error} == !defined $tk->{error};
		}
		is $bad_state, 0, "$file: the integer state rows of all $ticks ticks";
		SKIP: {
			skip $wide, 3 if $wide;
			is $bad_events, 0, "$file: every event, its time bit for bit";
			is $bad_segs, 0, "$file: every segment double bit for bit";
			is $bad_t, 0, "$file: t, n and error of every tick";
		}
	}
};

# ---- 2: the closed forms, the drift, ROLLING at the cut ------------------------------------
subtest 'mark 2: one tick against the closed forms; the frictionless drift; ROLLING at the cut' => sub {
	plan tests => 7;
	my $dt = 0.02;
	my $k = $rink->{world}{kinds}[0];
	my $mu = val($k->{mu}) * val($rink->{world}{mu}{r});
	my $dec = $mu * 9.81;
	my $out = $world->engine->advance([ [0, 50000, 100000, 0, 100000, 0] ], { t => 20000 });
	ok !$out->{error}, 'a puck at 1 m/s advances a tick without error';
	my $seg = $out->{segments}{0}[0];
	my $x_end = $seg->[2] + $seg->[4] * $seg->[1] + 0.5 * $seg->[6] * $seg->[1] * $seg->[1];
	my $v_end = $seg->[4] + $seg->[6] * $seg->[1];
	ok abs(($x_end - 0.5) - (1.0 * $dt - $dec * $dt * $dt / 2)) < 1e-12, 'one tick moves it v dt - mu g dt^2 / 2, to 1e-12';
	ok abs($v_end - (1.0 - $dec * $dt)) < 1e-12, 'one tick slows it by mu g dt, to 1e-12';
	is $out->{state}[0][5], 2, 'ROLLING at the cut';
	is $out->{t}, 0.02, 'the outcome ends at the horizon';
	my @row = (9, 50000, 100000, 0, 5000, 0);
	for (1 .. 100) {
		my $o = $frictionless->engine->advance([ [@row] ], { t => 20000 });
		@row = (9, $o->{state}[0][1], $o->{state}[0][2], 0, $o->{state}[0][3], $o->{state}[0][4]);
	}
	is_deeply [ @row[1, 4] ], [ 50000 + 100 * 100, 5000 ], 'the drift: a frictionless body at 0.05 m/s moves 1 mm a tick for 100 ticks and keeps its velocity (no speed floor)';
	my $long = $world->engine->advance([ [0, 50000, 100000, 0, 100000, 0] ], { t => 200000 });
	my @chain = (0, 50000, 100000, 0, 100000, 0);
	for (1 .. 10) {
		my $o = $world->engine->advance([ [@chain] ], { t => 20000 });
		@chain = (0, $o->{state}[0][1], $o->{state}[0][2], 0, $o->{state}[0][3], $o->{state}[0][4]);
	}
	ok abs($chain[1] - $long->{state}[0][1]) <= 10 && abs($chain[4] - $long->{state}[0][3]) <= 10, 'ten ticks against one long advance agree to the rounding of the chain (ten half-units)';
};

# ---- 3: the half-open cut -------------------------------------------------------------------
subtest 'mark 3: an event at exactly the horizon belongs to the next call' => sub {
	plan tests => 3;
	# a dyadic world: radius 1/16, a wall at 1, a horizon of half a second, a
	# speed and a distance whose products with 1e-5 are exact, so the root is
	# the same double as the horizon; on the rink itself every such root lands
	# a few ulps under 0.02 (plan_air_hockey/01, Results 7)
	my ($found, $horizon) = (undef, 500000 / 1e6);
	for my $r (0.0625, 0.125, 0.25) {
		for my $v (25000, 50000, 100000, 200000) {
			my $dist = $v / 2;
			my $cx = 100000 - int($r * 1e5 + 0.5) - $dist;
			next unless $v * 1e-5 == $v / 1e5 && $cx * 1e-5 == $cx / 1e5;
			my $s0 = -1 * ($cx * 1e-5 - 1.0) + 0 * (1.0 - 0) - $r;
			$found = { r => $r, v => $v, cx => $cx } if $s0 / ($v * 1e-5) == $horizon && !$found;
		}
	}
	ok $found, 'a dyadic pair meets the wall at exactly the horizon' or return;
	my $dw = Physics::Balls::World->new(L => 2, W => 1, R => $found->{r}, g => 9.81, mu => { s => 0, r => 0, sp => 0.044 },
		e => { bb => 0.9, c => 0.85, cf => 0, rc => 1 }, vmax => 8, kinds => [ { r => $found->{r}, m => 1, mu => 1, follow => 0 } ],
		walls => [ [1, 0, 1, 2] ], noses => [], gates => []);
	my $o1 = $dw->engine->advance([ [9, $found->{cx}, 100000, 0, $found->{v}, 0] ], { t => 500000 });
	my $o2 = $dw->engine->advance([ [9, $o1->{state}[0][1], $o1->{state}[0][2], 0, $o1->{state}[0][3], $o1->{state}[0][4]] ], { t => 500000 });
	ok !(grep { $_->[1] eq 'wall' } @{ $o1->{events} }), 'the call ending at the horizon does not take the event';
	ok((grep { $_->[1] eq 'wall' && $_->[0] == 0 } @{ $o2->{events} }), 'the next call takes it at t = 0');
};

# ---- 4: the pin -----------------------------------------------------------------------------
subtest 'mark 4: the pin, a mallet driven at the puck against a cushion for fifty ticks' => sub {
	plan tests => 5;
	my $W = 100000;
	my $R = int(val($rink->{world}{kinds}[0]{r}) * 1e5 + 0.5);
	my $MR = int(val($rink->{world}{kinds}[1]{r}) * 1e5 + 0.5);
	my $reach = ($R + $MR) * 1e-5;
	my @puck = (0, $W - $R, 100000, 0, 0, 0);
	my @mallet = (1, $W - $R - ($R + $MR) - 2000, 100000, 1, 0, 0);
	my ($errs, $max_events, $max_ratio, $min_gap, $worst_inside) = (0, 0, 0, 1e9, 0);
	for my $i (1 .. 50) {
		my $vx = ($W + 20000 - $mallet[1]) / 0.02;
		$vx = 240000 if $vx > 240000;
		$mallet[4] = int($vx + 0.5); $mallet[5] = 0;
		my $speed = sqrt($puck[4] ** 2 + $puck[5] ** 2);
		if ($speed > 600000) { my $f = 600000 / $speed; $puck[4] = int($puck[4] * $f + ($puck[4] < 0 ? -0.5 : 0.5)); $puck[5] = int($puck[5] * $f + ($puck[5] < 0 ? -0.5 : 0.5)); }
		my $o = $world->engine->advance([ [@puck], [@mallet] ], { t => 20000 });
		$errs++ if $o->{error};
		$max_events = $o->{n} if $o->{n} > $max_events;
		my ($ps) = grep { $_->[0] == 0 } @{ $o->{state} };
		my ($ms) = grep { $_->[0] == 1 } @{ $o->{state} };
		@puck = (0, $ps->[1], $ps->[2], 0, $ps->[3], $ps->[4]);
		@mallet = (1, $ms->[1], $ms->[2], 1, $ms->[3], $ms->[4]);
		my $inside = ($ps->[1] - ($W - $R)) * 1e-5; $worst_inside = $inside if $inside > $worst_inside;
		my $pspeed = sqrt($ps->[3] ** 2 + $ps->[4] ** 2) * 1e-5;
		my $mspeed = sqrt($ms->[3] ** 2 + $ms->[4] ** 2) * 1e-5;
		$max_ratio = $pspeed / $mspeed if $mspeed > 0 && $pspeed / $mspeed > $max_ratio;
		my $gap = sqrt(($ps->[1] - $ms->[1]) ** 2 + ($ps->[2] - $ms->[2]) ** 2) * 1e-5; $min_gap = $gap if $gap < $min_gap;
	}
	is $errs, 0, 'every tick error-free';
	ok $max_events < 100, "events a tick under the storm limit (at most $max_events)";
	ok $worst_inside <= 0.001, sprintf('the puck never past the cushion line by more than a millimetre (%.3f mm)', $worst_inside * 1000);
	ok $max_ratio <= 10, sprintf('the puck at most ten times the mallet\'s speed (%.2f)', $max_ratio);
	ok $min_gap >= $reach - 1e-4, sprintf('the pair never closer than the sum of radii (%.3f mm against %.1f)', $min_gap * 1000, $reach * 1000);
};

# ---- 5: a goal, the facade, the refusals, the version ----------------------------------------
subtest 'mark 5: a goal through a gate; the facade and Ball objects; the refusals; the ABI version' => sub {
	plan tests => 14;
	my @row = (0, 50000, 100000, 0, 0, 300000);
	my ($pot, $o);
	for (1 .. 60) {
		$o = $world->engine->advance([ [@row] ], { t => 20000 });
		($pot) = grep { $_->[1] eq 'pot' } @{ $o->{events} };
		last if $pot;
		@row = (0, $o->{state}[0][1], $o->{state}[0][2], 0, $o->{state}[0][3], $o->{state}[0][4]);
	}
	ok $pot && $pot->[3] == 2, 'a puck up the middle crosses the far gate: a pot naming mouth 2';
	is $o->{holed}[0][0], 0, 'and is holed';
	is_deeply [ @{ $o->{state}[0] }[3 .. 5] ], [ 0, 0, 3 ], 'its state row carries zero velocity and mode 3';
	my $out = Physics::Balls->advance($world, layout => [ Physics::Balls::Ball->new(id => 0, x => 50000, y => 100000, vx => 100000, vy => 0) ], t => 20000);
	ok !$out->error, 'the facade advances a Ball object';
	is $out->mode_of(0), 'rolling', 'mode_of reads the word';
	ok $out->to_payload->{state}, 'to_payload carries the state';
	is scalar @{ Physics::Balls->strike($world, layout => [ [0, 50000, 100000, 0], [1, 90000, 5000, 1] ], ball => 0, dx => 1_000_000, dy => 0, power => 200)->state }, 0, 'a strike carries no state';
	my $five = Physics::Balls->advance($world, layout => [ [0, 50000, 100000, 0, 0] ], t => 20000);
	is $five->code, 'bad_layout', 'a row of five is bad_layout';
	is(Physics::Balls->advance($world, layout => [ [0, 50000, 100000, 0, 200_000_000, 0] ], t => 20000)->code, 'bad_velocity', 'a velocity out of range is bad_velocity');
	is(Physics::Balls->advance($world, layout => [ [0, 50000, 100000, 0, 0, 0] ], t => 0)->code, 'bad_horizon', 't 0 is bad_horizon');
	is(Physics::Balls->advance($world, layout => [ [0, 50000, 100000, 0, 0, 0] ], t => 40_000_001)->code, 'bad_horizon', 't over forty seconds is bad_horizon');
	is(Physics::Balls->advance($world, layout => [ [0, 50000, 100000, 7, 0, 0] ], t => 20000)->code, 'bad_kind', 'a kind the world lacks is bad_kind');
	ok(Physics::Balls->abi_version >= 4, 'abi_version is at least 4');
	ok $world->engine->bad_size_refused, 'a short pb_tick is refused with the short desc and shot';
};

done_testing;
