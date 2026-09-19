#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Config;

# Ball kinds (0.04, plan_bowling 02). The marks, in order:
#
#   1  a world with no kinds is the old world exactly, and a world whose kinds
#      are all the default (R, mass 1, mu 1, rs R, vfall 0) replays a table
#      fixture bit-identically through rows that name the kind
#   2  the C is the JavaScript: every lane fixture recorded by
#      plan_bowling/prototype/record.js from the forked physics.js is
#      bit-identical here, events, rest, holed, down, peak and segments
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

sub hexd { my ($v) = @_; return unpack 'H*', pack 'd>', ($v == 0 ? 0 : $v) }
sub hexes { my ($row) = @_; return join ' ', map { hexd($_) } @$row }
sub lane_world {
	my (%over) = @_;
	my $w = $lane->{world};
	return Physics::Balls::World->new(
		L => $w->{L}, W => $w->{W}, R => $w->{R}, g => $w->{g}, vmax => $w->{vmax}, mu => $w->{mu}, e => $w->{e},
		walls => $w->{walls}, noses => $w->{noses}, gates => $w->{gates}, kinds => $w->{kinds}, %over,
	);
}
my $world = lane_world();

# ---- 2: the C is the JavaScript ---------------------------------------------------------
for my $f (@fx) {
	my $label = "lane/$f->{id}";
	my $out = Physics::Balls->strike($world, layout => $f->{layout}, %{ $f->{shot} });
	ok !$out->error, "$label: the engine plays it (" . scalar(@{ $out->events }) . ' events)' or diag($out->message);
	is join("\n", map { hexd($_->[0]) . " $_->[1] $_->[2]" . (defined $_->[3] ? " $_->[3]" : '') } @{ $out->events }),
		join("\n", map { hexd($_->[0]) . " $_->[1] $_->[2]" . (defined $_->[3] ? " $_->[3]" : '') } @{ $f->{events} }),
		"$label: the events are identical, times bit for bit";
	# the prototype's rest rows carry the kind; the dist's are [id, x, y], the 0.03 contract
	is_deeply [ $out->rest, $out->holed, [ map { [ @$_[0 .. 2], hexd($_->[3]) ] } @{ $out->down } ], { map { $_ => hexd($out->peak->{$_}) } keys %{ $out->peak } } ],
		[ [ map { [ @$_[0 .. 2] ] } @{ $f->{rest} } ], $f->{holed}, [ map { [ @$_[0 .. 2], hexd($_->[3]) ] } @{ $f->{down} } ], { map { $_ => hexd($f->{peak}{$_}) } keys %{ $f->{peak} } } ],
		"$label: rest, holed, down and peak are identical";
	my (@mine, @theirs);
	for my $id (sort { $a <=> $b } keys %{ $f->{segments} }) {
		push @theirs, map { hexes($_) } @{ $f->{segments}{$id} };
		push @mine, map { hexes($_) } @{ $out->segments->{$id} || [] };
	}
	is join("\n", @mine), join("\n", @theirs), "$label: the segments are bit-identical to the prototype's (" . scalar(@theirs) . ' segments)'
		or diag("on $Config{archname}, $Config{cc}");
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
	cmp_ok abs($after0->[4] - $keep * $v), '<', 1e-9, sprintf('mark 3: the ball keeps (m1 - e m2)/(m1 + m2) = %.5f of %.3f m/s', $keep, $v);
	cmp_ok abs($after1->[4] - $give * $v), '<', 1e-9, sprintf('mark 3: the pin takes m1 (1 + e)/(m1 + m2) = %.5f of it', $give);
	cmp_ok abs($m1 * $after0->[4] + $m2 * $after1->[4] - $m1 * $v), '<', 1e-9, 'mark 3: momentum is conserved';
	cmp_ok $after0->[4], '>', 0, 'mark 3: the ball carries through, which at equal mass it would not (it would keep 0.225)';
	# ---- 4: the peak is the peak
	cmp_ok abs($out->peak_of(1) - $after1->[4]), '<', 1e-12, 'mark 4: the pin\'s peak is its speed after the hit';
	my $release = 0.3 + 0.36 * (9.5 - 0.3);
	cmp_ok abs($out->peak_of(0) - $release), '<', 1e-12, 'mark 4: the ball\'s peak is its release speed';
	# ---- 5: down
	ok $out->downed(1), 'mark 5: the pin, past 0.25 m/s, went down';
	ok !(grep { $_->[0] == 1 } @{ $out->rest }) && !$out->potted(1), 'mark 5: and is in neither rest nor holed';
	is scalar(grep { $_->[1] eq 'down' && $_->[2] == 1 } @{ $out->events }), 1, 'mark 5: with one down event';
	ok((grep { $_->[0] == 0 } @{ $out->rest }), 'mark 5: the ball rests');
	my $d = $out->downed(1);
	cmp_ok abs($d->[1] * 1e-5 - ($out->segments->{1}[-1][2] + $out->segments->{1}[-1][4] * $out->segments->{1}[-1][1] + 0.5 * $out->segments->{1}[-1][6] * $out->segments->{1}[-1][1] ** 2)), '<', 1e-5,
		'mark 5: the down row is where its last segment ends';
}
{
	# the slowest ball there is (power 0 is 0.3 m/s) glancing off a pin set
	# 0.15 m to the side of its line, so the pin takes 0.45 of the closing speed
	# times 1.257, about 0.17 m/s, below 0.25: it moves a little and stands
	my $out = Physics::Balls->strike($box, layout => [ [0, 50000, 200000, 0], [1, 60000, 215000, 1] ], %roll, power => 0);
	ok !$out->error && !$out->downed(1), 'mark 5: a pin nudged at ' . sprintf('%.3f', $out->peak_of(1)) . ' m/s, below 0.25, is not down' or diag $out->message;
	my ($r) = grep { $_->[0] == 1 } @{ $out->rest };
	ok $r && ($r->[1] != 60000 || $r->[2] != 215000), 'mark 5: it stands where it was pushed to, ' . ($r ? sprintf('%.1f mm off its spot', sqrt(($r->[1] - 60000) ** 2 + ($r->[2] - 215000) ** 2) / 100) : 'gone');
	cmp_ok $out->peak_of(1), '>', 0, 'mark 5: though it did move';
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
	is(Physics::Balls->abi_version, 3, 'mark 7: abi_version is 3');
	ok $box->engine->bad_size_refused, 'mark 7: a v2 description and a v2 shot with a size smaller than the struct are still refused';
}
