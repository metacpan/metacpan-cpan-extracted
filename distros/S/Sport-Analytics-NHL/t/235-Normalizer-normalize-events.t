#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 36218;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Tools qw(:parser);
use Sport::Analytics::NHL::Normalizer;
use Storable qw(retrieve dclone);

my @merged = Sport::Analytics::NHL::merge({}, {reports_dir => 't/data/'}, 201120010);
my $boxscore = retrieve $merged[0];
use Data::Dumper;
my $round = 0;
TEST:
for my $event (@{$boxscore->{events}}) {
	Sport::Analytics::NHL::Normalizer::normalize_event_header(
		$event, $boxscore
	) unless $round;
	is($event->{game_id}, $boxscore->{_id}, 'event has game');
	like($event->{zone}, qr/^(OFF|DEF|NEU|UNK)$/, 'event has zone')
		unless is_noplay_event($event);
	is(length($event->{strength}), 2, 'event has strength');
	for my $field (qw(game_id period season stage so ts distance)) {
		like($event->{$field}, qr/^\d+$/, "field $field a number")
			if $field ne 'distance' || defined $event->{$field};
	}
	like($event->{coords}[0], qr/^\d+$/, 'coord x a number')
		if $event->{coords};
	like($event->{coords}[1], qr/^\d+$/, 'coord y a number')
		if $event->{coords};
	like($event->{t}, qr/^(-1|0|1)$/, 'event t index ok');
	Sport::Analytics::NHL::Normalizer::normalize_event_players_teams(
		$event, $boxscore
	) unless $round;
	is($event->{team2}, $boxscore->{teams}[1-$event->{t}]{name})
		if $event->{t} != -1;
	for my $field (qw(en player1 player2 assist1 assist2)) {
		like($event->{$field}, qr/^\d+$/, "field $field ok")
			if exists $event->{$field};
	}
	Sport::Analytics::NHL::Normalizer::normalize_event_on_ice(
		$event
	) unless $round;
	if ($event->{on_ice}) {
		for my $t (0,1) {
			for my $o (@{$event->{on_ice}[$t]}) {
				like($o, qr/^8(4|5)\d{5}$/, 'valid player id on ice');
			}
		}
	}
	my $was_event = dclone $event;
	my $repeat_2 = $round;
	TEST_EVENT:
	for ($event->{type}) {
		when ('GOAL') {
			Sport::Analytics::NHL::Normalizer::normalize_goal_event($event) unless $repeat_2;
			for my $field (qw(en player1 player2 gwg penaltyshot)) {
				like($event->{$field}, qr/^0|1|(\d{7})$/, "goal $field ok")
					unless $field eq 'penaltyshot' && ! $repeat_2;
			}
			is_deeply(
				[$event->{assist1}, $event->{assist2}],
				$event->{assists},
				'assists ok',
			);
		}
		when ('PENL') {
			Sport::Analytics::NHL::Normalizer::normalize_penl_event($event) unless $repeat_2;
			ok($event->{ps_penalty}, 'ps penalty') if $event->{length} == 0;
			ok($event->{penalty}, 'penalty defined');
			like($event->{length}, qr/^(0|2|4|5|10)$/, 'penalty length ok');
			like($event->{servedby}, qr/^8(4|5)\d{5}$/, 'servedby ok')
				if $event->{servedby};
		}
		when ('FAC')  {
			like($event->{winning_team}, qr/^\w{3}$/, 'FAC winning team ok')
				if $repeat_2;
		}
		if ($repeat_2) {
			if ($event->{type} ne 'GOAL') {
				ok(!defined $event->{assist1}, 'no goal no assist1');
				ok(!defined $event->{assist2}, 'no goal no assist2');
				ok(!defined $event->{assists}, 'no goal no assists');
			}
			ok(defined $event->{shot_type}, 'shot type defined')
				if $event->{type} eq 'MISS' || $event->{type} eq 'GOAL'
				|| $event->{type} eq 'SHOT' || $event->{type} eq 'BLOCK';
			my @fields = keys %{$event};
			for my $field (@fields) {
				ok(defined $field);
				next if $field eq 'file' || ref $event->{$field};
				if ($event->{$field} =~ /\D/) {
					is($event->{$field}, uc($event->{$field}), 'all UC ok');
				}
				else {
					like($event->{$field}, qr/^\d+$/, 'numeric field ok');
				}
			}
		}
	}
	$event = $was_event;
	Sport::Analytics::NHL::Normalizer::normalize_event_by_type(
		$event
	) unless $repeat_2;
	$repeat_2++;
	goto TEST_EVENT if $repeat_2 == 1;
}
$round++;
$boxscore = retrieve $merged[0];
Sport::Analytics::NHL::Normalizer::normalize_events($boxscore);
goto TEST if $round == 1;
undef $Sport::Analytics::NHL::Normalizer::EVENT;
