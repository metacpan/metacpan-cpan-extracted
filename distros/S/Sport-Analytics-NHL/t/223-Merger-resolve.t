#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 10;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Merger;
use Sport::Analytics::NHL::Tools qw(:db);
use Sport::Analytics::NHL::Test;

use Data::Dumper;

my $report = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'BS', 't/data/2011/0002/0010'
);
$report->build_resolve_cache();
$Sport::Analytics::NHL::Merger::PLAYER_RESOLVE_CACHE = $report->{resolve_cache};

$report->set_event_extra_data();
my $ro = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'RO', 't/data/2011/0002/0010'
);
for my $t (0,1) {
	$ro->{teams}[$t]{name} = resolve_team($ro->{teams}[$t]{name});
	Sport::Analytics::NHL::Merger::resolve_report_roster($ro->{teams}[$t]{roster}, $report, $t);
	Sport::Analytics::NHL::Test::test_team_id($ro->{teams}[$t]{name}, 'team name updated');
	for my $player (@{$ro->{teams}[$t]{roster}}) {
		Sport::Analytics::NHL::Test::test_player_id($player->{_id}, 'id resolved')
			unless $player->{position} eq 'G' && !$player->{start};
	}
};
is($TEST_COUNTER->{Curr_Test}, 40, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

my $pl = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'PL', 't/data/2011/0002/0010'
);
bless $pl, 'Sport::Analytics::NHL::Report::PL';
isa_ok($pl, 'Sport::Analytics::NHL::Report');
$pl->set_event_extra_data();
for my $event (@{$pl->{events}}) {
	Sport::Analytics::NHL::Merger::resolve_report_event_teams($event, $pl);
	Sport::Analytics::NHL::Test::test_team_id($event->{team1}, 'team1 name updated')
		if $event->{team1};
	Sport::Analytics::NHL::Test::test_team_id($event->{team2}, 'team2 name updated')
		if $event->{team2};
	Sport::Analytics::NHL::Merger::resolve_report_event_fields($event, $report);
	for my $field (qw(player1 player2 assist1 assist2 servedby)) {
		Sport::Analytics::NHL::Test::test_player_id($event->{$field}, "$field resolved")
			if $event->{$field};
	}
	Sport::Analytics::NHL::Merger::resolve_report_on_ice($event, $report);
	for my $t (0,1) {
		for my $on_ice (@{$event->{on_ice}[$t]}) {
			Sport::Analytics::NHL::Test::test_player_id($on_ice, "on ice $on_ice resolved");
		}
	}
}

is($TEST_COUNTER->{Curr_Test}, 4499, 'events all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

$ro = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'RO', 't/data/2011/0002/0010'
);
Sport::Analytics::NHL::Merger::resolve_report($report, $ro);
for my $t (0,1) {
	Sport::Analytics::NHL::Test::test_team_id($ro->{teams}[$t]{name}, 'team name updated');
	for my $player (@{$ro->{teams}[$t]{roster}}) {
		Sport::Analytics::NHL::Test::test_player_id($player->{_id}, 'id resolved')
			unless $player->{position} eq 'G' && !$player->{start};
	}
};
is($TEST_COUNTER->{Curr_Test}, 4539, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

$pl = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'PL', 't/data/2011/0002/0010'
);
isa_ok($pl, 'Sport::Analytics::NHL::Report');
Sport::Analytics::NHL::Merger::resolve_report($report, $pl);
for my $event (@{$pl->{events}}) {
	Sport::Analytics::NHL::Test::test_team_id($event->{team1}, 'team1 name updated')
		if $event->{team1};
	Sport::Analytics::NHL::Test::test_team_id($event->{team2}, 'team2 name updated')
		if $event->{team2};
	for my $field (qw(player1 player2 assist1 assist2 servedby)) {
		Sport::Analytics::NHL::Test::test_player_id($event->{$field}, "$field resolved")
			if $event->{$field};
	}
	for my $t (0,1) {
		for my $on_ice (@{$event->{on_ice}[$t]}) {
			Sport::Analytics::NHL::Test::test_player_id($on_ice, "$on_ice resolved");
		}
	}
}

is($TEST_COUNTER->{Curr_Test}, 8998, 'events all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
