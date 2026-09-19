#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();
use JSON::PP ();
use FindBin ();
use IPC::Open2 ();

# The differential fuzz harness: random input logs run through the C engine
# and through the JavaScript prototype under node, comparing the state hash
# EVERY TICK rather than at the end, so a divergence names a tick. This is
# the single highest-value test in the plan, because it is the only thing
# that turns "we were careful" into evidence. It needs node and the prototype
# beside this checkout, and it FAILS rather than skips when they are missing:
# a fallback that reports PASS is a failing test.

use Physics::Terrain;

my $N = $ENV{PT_DIFF_TURNS} || 200;
my $proto = "$FindBin::Bin/../../plan_crater/prototype";
my $node = $ENV{NODE} || 'node';

plan tests => 2 + $N;

ok -f "$proto/hashes.js", "the prototype's hashes.js is at $proto";
my $version = `$node --version 2>/dev/null`;
chomp $version if defined $version;
ok $version && $version =~ /^v(\d+)/ && $1 >= 18, "node is on the path (" . ($version || 'missing') . ")";

my $counter = 0;
sub word { my ($label) = @_; return unpack 'N', Digest::SHA::sha256("differential:$label:" . $counter++) }
sub below { my ($label, $n) = @_; return word($label) % $n }
sub between { my ($label, $lo, $hi) = @_; return $lo + below($label, $hi - $lo + 1) }
my ($L, $R, $J) = (Physics::Terrain::LEFT(), Physics::Terrain::RIGHT(), Physics::Terrain::JUMP());

for my $seed (1 .. $N) {
	my $teams = between('teams', 2, 4);
	my $wind = below('windset', 3) ? undef : between('wind', -20, 20);
	my %setup = (seed => $seed, gen => undef, sculpt => [], place => 'teams', teams => $teams, perTeam => 4);
	$setup{wind} = $wind if defined $wind;
	my $field = Physics::Terrain->new(seed => $seed, teams => $teams, place => 'teams', (defined $wind ? (wind => $wind) : ()));
	my @alive = grep { $_->{alive} } @{ $field->bodies };
	my $active = $alive[ below('active', scalar @alive) ]{index};
	my @inputs;
	my ($t, $bits) = (0, 0);
	for (1 .. between('segs', 2, 9)) {
		my $choice = below('choice', 6);
		my $nb = $choice == 0 ? 0 : $choice == 1 ? $L : $choice == 2 ? $R : $choice == 3 ? ($L | $J) : $choice == 4 ? ($R | $J) : $bits;
		if ($nb != $bits) { push @inputs, [$t, $nb]; $bits = $nb }
		$t += between('dur', 4, 140);
		if ($bits & $J) { my $nb2 = $bits & ~$J; push @inputs, [$t, $nb2]; $bits = $nb2; $t += between('dur2', 10, 90) }
	}
	push @inputs, [$t, 0] if $bits;
	$t += between('aim', 1, 60);
	my $angle = between('angle', -700, 1100);
	$angle = 2048 - $angle if below('facing', 2);
	my $shot = below('noshot', 12) ? { tick => $t, weapon => below('weapon', 5), angle => $angle & 4095, power => between('power', 1, 100) } : undef;

	my @mine;
	$field->start_turn($active);
	my ($phase, $fired) = ('live', 0);
	while ($phase ne 'done') {
		my $now = ($shot && !$fired && $shot->{tick} == $field->turn_tick) ? do { $fired = 1; $shot } : undef;
		my $b = 0;
		for my $in (@inputs) { $b = $in->[1] if $in->[0] <= $field->turn_tick }
		$phase = $field->advance($b, $now);
		push @mine, join ' ', $field->turn_tick, $field->hash;
	}
	push @mine, join ' ', 'end', $field->turn_tick, ($field->error // 'none');

	my $req = JSON::PP->new->encode({ setup => \%setup, active => $active, inputs => \@inputs, shot => $shot });
	my $pid = IPC::Open2::open2(my $out, my $in, $node, "$proto/hashes.js");
	print {$in} $req;
	close $in;
	my @theirs = map { chomp; $_ } <$out>;
	close $out;
	waitpid $pid, 0;

	my $first = -1;
	for my $i (0 .. ($#mine > $#theirs ? $#mine : $#theirs)) {
		next if defined $mine[$i] && defined $theirs[$i] && $mine[$i] eq $theirs[$i];
		$first = $i;
		last;
	}
	is $first, -1, "seed $seed: " . scalar(@mine) . " ticks, every state hash equal" or diag("first difference at line $first: C '" . ($mine[$first] // '') . "' node '" . ($theirs[$first] // '') . "'; shot " . ($shot ? "w$shot->{weapon} a$shot->{angle} p$shot->{power} t$shot->{tick}" : 'none') . " inputs " . JSON::PP->new->encode(\@inputs));
}
