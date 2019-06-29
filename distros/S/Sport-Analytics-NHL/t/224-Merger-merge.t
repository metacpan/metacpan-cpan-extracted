#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 89;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Merger;
use Sport::Analytics::NHL::Test;

my $boxscore = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'BS', 't/data/2011/0002/0010'
);
$boxscore->build_resolve_cache();
$Sport::Analytics::NHL::Merger::PLAYER_RESOLVE_CACHE = $boxscore->{resolve_cache};

$boxscore->set_event_extra_data();
my $ro = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'RO', 't/data/2011/0002/0010'
);
Sport::Analytics::NHL::Merger::resolve_report($boxscore, $ro);
Sport::Analytics::NHL::Merger::merge_me(
	$boxscore, $ro, \@Sport::Analytics::NHL::Merger::MERGE_HEADER
);
for my $header (@Sport::Analytics::NHL::Merger::MERGE_HEADER) {
	is($boxscore->{$header}, $ro->{$header}, "header $header merged");
}
Sport::Analytics::NHL::Merger::merge_teams(
	$boxscore, $ro,
);

for my $t (0,1) {
	is($boxscore->{teams}[$t]{coach}, $ro->{teams}[$t]{coach}, 'coach merged');
	for my $player (@{$ro->{teams}[$t]{roster}}) {
		my $bs_player = ${$boxscore->{resolve_cache}{$boxscore->{teams}[$t]{name}}{$player->{number}}};
		for my $field (qw(start state)) {
			is($bs_player->{$field}, $player->{$field}, "player field $field merged")
				if defined $bs_player;
		}
	}
};

my $pl = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'PL', 't/data/2011/0002/0010'
);
Sport::Analytics::NHL::Merger::resolve_report($boxscore, $pl);
$BOXSCORE = $boxscore;
Sport::Analytics::NHL::Merger::merge_events(
	$boxscore, $pl,
);
$Sport::Analytics::NHL::Test::THIS_SEASON = $boxscore->{season};
Sport::Analytics::NHL::Test::test_merged_events($boxscore->{events});
is($TEST_COUNTER->{Curr_Test}, 3525, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

$boxscore = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'BS', 't/data/2011/0002/0010'
);
$boxscore->build_resolve_cache();
$Sport::Analytics::NHL::Merger::PLAYER_RESOLVE_CACHE = $boxscore->{resolve_cache};

$boxscore->set_event_extra_data();

for my $type (qw(PL RO GS ES TV TH)) {
	my $doc = Sport::Analytics::NHL::retrieve_compiled_report(
		{}, 201120010, $type, 't/data/2011/0002/0010'
	);
	merge_report($boxscore, $doc);
}

test_merged_boxscore($boxscore);
is($TEST_COUNTER->{Curr_Test}, 8535, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

ok(defined $boxscore->{shifts}, 'shifts merged');
isa_ok($boxscore->{shifts}, 'ARRAY', 'it is an array of shifts');
