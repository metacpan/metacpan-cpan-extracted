#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 2738;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Normalizer;
use Storable;

my @merged = Sport::Analytics::NHL::merge({}, {reports_dir => 't/data/'}, 201120010);
my $boxscore = retrieve $merged[0];
use Data::Dumper;
my $round = 0;
TEST:
for my $t (0,1) {
	my $team = $boxscore->{teams}[$t];
	Sport::Analytics::NHL::Normalizer::normalize_team($team) unless $round;
	for my $stat (keys %{$team->{stats}}) {
		like($team->{stats}{$stat}, qr/[+-]?([0-9]*[.])?[0-9]+/, "team $stat a number");
	}
	for my $field (qw(pull shots score)) {
		like($team->{$field}, qr/[+-]?([0-9]*[.])?[0-9]+/, "team $field a number");
	}
	isa_ok($team->{scratches}, 'ARRAY', 'scratches array ok');
	ok(! exists $team->{_decision}, 'pseudo-decision removed');
	Sport::Analytics::NHL::Normalizer::normalize_players($team) unless $round;
	for my $player (@{$team->{roster}}) {
		for (keys %{$player}) {
			my $field = $_;
			when ('position') {}
			when ('name') {}
			when ('status') {
				like($player->{$field}, qr/^(C|A| )$/, 'status ok');
			}
			when ('start') {
				like($player->{$field}, qr/^(0|1|2)$/, 'start ok');
			}
			when ('plusMinus') {
				like($player->{$field}, qr/^\-?\d+$/, '+- ok');
			}
			when ('decision') {
				if ($player->{position} eq 'G') {
					like($player->{$field}, qr/^(W|L|O|T|N)$/, 'decision ok');
				}
				else {
					fail("skater $player->{_id} should not have decision");
				}
			}
			when ('team') {
				is($player->{team}, $team->{name}, 'team in player ok');
			}
			default {
				like(
					$player->{$field},
					qr/[+-]?([0-9]*[.])?[0-9]+/, "stat $field a number"
				);
			}
		}
		isa_ok(
			$Sport::Analytics::NHL::Normalizer::PLAYER_IDS->{$player->{_id}},
			'REF', 'player registered in cache'
		);
	}
}
$round++;
$boxscore = retrieve $merged[0];
Sport::Analytics::NHL::Normalizer::normalize_teams($boxscore);
goto TEST if $round == 1;
