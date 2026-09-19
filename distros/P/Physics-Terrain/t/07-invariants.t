#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

# The invariants, over seeded random turns on generated fields with four
# teams. Every number the engine produces must satisfy them whatever the
# input log:
#
#   - every turn settles under the cap without an engine error;
#   - health never rises, and stays between 0 and 100;
#   - a body that is alive is inside the field, standing, with no velocity
#     left over; a body that left the field is reported dead and out;
#   - every position and velocity stays inside the declared box, 2^30 in
#     fixed point, so no product of two of them can pass 2^63 and no
#     descaled value 2^53: this is the one invariant the integer decision
#     buys and nothing else checks;
#   - a turn replayed from a snapshot ends in the same state hash.
#
# The randomness is sha256 of a fixed seed, so a failure replays.

use Physics::Terrain;

my $N = $ENV{PT_RANDOM_TURNS} || 200;
my $BOX = 1 << 30;

plan tests => 7;

my $counter = 0;
sub word { my ($label) = @_; return unpack 'N', Digest::SHA::sha256("invariants:$label:" . $counter++) }
sub below { my ($label, $n) = @_; return word($label) % $n }
sub between { my ($label, $lo, $hi) = @_; return $lo + below($label, $hi - $lo + 1) }

my ($L, $R, $J) = (Physics::Terrain::LEFT(), Physics::Terrain::RIGHT(), Physics::Terrain::JUMP());

sub random_turn {
	my ($field) = @_;
	my @alive = grep { $_->{alive} } @{ $field->bodies };
	my $active = $alive[ below('active', scalar @alive) ]{index};
	my @inputs;
	my ($t, $bits) = (0, 0);
	for (1 .. between('segs', 2, 7)) {
		my $choice = below('choice', 6);
		my $nb = $choice == 0 ? 0 : $choice == 1 ? $L : $choice == 2 ? $R : $choice == 3 ? ($L | $J) : $choice == 4 ? ($R | $J) : $bits;
		if ($nb != $bits) { push @inputs, [$t, $nb]; $bits = $nb }
		$t += between('dur', 8, 110);
		if ($bits & $J) { my $nb2 = $bits & ~$J; push @inputs, [$t, $nb2]; $bits = $nb2; $t += between('dur2', 20, 80) }
	}
	push @inputs, [$t, 0] if $bits;
	$t += between('aim', 5, 40);
	my $angle = between('angle', -600, 1000);
	$angle = 2048 - $angle if below('facing', 2);
	return ($active, \@inputs, { tick => $t, weapon => below('weapon', 5), angle => $angle & 4095, power => between('power', 20, 100) });
}

my (@errors, @health, @bodies, @box, @replay);
my ($turns, $maxv, $maxp) = (0, 0, 0);
for my $seed (1 .. $N) {
	my $field = Physics::Terrain->new(seed => $seed, teams => 4);
	my ($active, $inputs, $shot) = random_turn($field);
	my %before = map { $_->{index} => $_->{hp} } @{ $field->bodies };
	my $snap = $field->snapshot;
	$field->start_turn($active);
	my $phase = 'live';
	my $fired = 0;
	while ($phase ne 'done') {
		my $now = (!$fired && $shot->{tick} == $field->turn_tick) ? do { $fired = 1; $shot } : undef;
		my $bits = 0;
		for my $in (@$inputs) { $bits = $in->[1] if $in->[0] <= $field->turn_tick }
		$phase = $field->advance($bits, $now);
		for my $b (@{ $field->bodies }) {
			for my $k (qw(x y vx vy)) {
				push @box, "seed $seed tick " . $field->turn_tick . ": body $b->{index} $k = $b->{$k}" if abs($b->{$k}) >= $BOX;
				$maxv = abs $b->{$k} if $k =~ /^v/ && abs($b->{$k}) > $maxv;
				$maxp = abs $b->{$k} if $k =~ /^[xy]$/ && abs($b->{$k}) > $maxp;
			}
		}
		last if @box > 5;
	}
	my $out = $field->outcome;
	$turns++;
	push @errors, "seed $seed: $out->{error}" if $out->{error};
	push @errors, "seed $seed: never settled" if $out->{settledAt} < 0 && !$out->{error};
	my %died = map { $_->[2] => $_->[3] } grep { $_->[1] eq 'die' } @{ $out->{events} };
	for my $b (@{ $field->bodies }) {
		push @health, "seed $seed: body $b->{index} rose from $before{$b->{index}} to $b->{hp}" if $b->{hp} > $before{ $b->{index} };
		push @health, "seed $seed: body $b->{index} hp $b->{hp}" if $b->{hp} < 0 || $b->{hp} > 100;
		if ($b->{alive}) {
			my ($cx, $cy) = (int($b->{x} / 256), int($b->{y} / 256));
			push @bodies, "seed $seed: body $b->{index} alive outside the field at $cx,$cy" if $cx < 0 || $cx >= 1280 || $cy < 0 || $cy >= 640;
			push @bodies, "seed $seed: body $b->{index} alive but still moving (mode $b->{mode}, v $b->{vx},$b->{vy})" if $b->{mode} != 0 || $b->{vx} || $b->{vy};
		} else {
			push @bodies, "seed $seed: body $b->{index} dead with health $b->{hp}" if $b->{hp} != 0;
			push @bodies, "seed $seed: body $b->{index} dead with no die event" unless exists $died{ $b->{index} } || $before{ $b->{index} } == 0;
		}
	}
	my @h1 = $field->hash;
	$field->restore($snap);
	my $again = $field->run_turn($active, $inputs, $shot);
	my @h2 = $field->hash;
	push @replay, "seed $seed: hash [@h1] then [@h2]" if "@h1" ne "@h2";
	push @replay, "seed $seed: the replay's events differ" unless join('|', map { "@$_" } @{ $again->{events} }) eq join('|', map { "@$_" } @{ $out->{events} });
}

is_deeply \@errors, [], "$turns random turns settled under the cap with no engine error" or diag(join "\n", @errors[0 .. 4]);
is_deeply \@health, [], 'health never rose and stayed between 0 and 100' or diag(join "\n", @health[0 .. 4]);
is_deeply \@bodies, [], 'every survivor is inside the field and still; every death has its event' or diag(join "\n", @bodies[0 .. 4]);
is_deeply \@box, [], "every position and velocity stayed inside the box (max |v| $maxv, max |p| $maxp of 2^30)" or diag(join "\n", @box[0 .. 4]);
cmp_ok $maxv, '<', 65536, 'no velocity ever needed more than 16 bits';
cmp_ok $maxp, '<', 1280 * 256 + 64 * 256, 'no position more than 64 cells past the field';
is_deeply \@replay, [], 'every turn replayed from its snapshot to the same hash and events' or diag(join "\n", @replay[0 .. 4]);
