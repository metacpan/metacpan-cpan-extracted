#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 7;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Merger;

my $report = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'BS', 't/data/2011/0002/0010'
);
$report->build_resolve_cache();
my $player;
use Data::Dumper;
$Sport::Analytics::NHL::Merger::PLAYER_RESOLVE_CACHE = $report->{resolve_cache};
$player = Sport::Analytics::NHL::Merger::find_player({_id => 8471703,number=>9}, $report->{teams}[0]);
is($player->{_id}, 8471703);
$player = Sport::Analytics::NHL::Merger::find_player({number => 9}, $report->{teams}[0]);
is($player->{_id}, 8471703);
$player = Sport::Analytics::NHL::Merger::find_player({name => 'DOWNIE'}, $report->{teams}[0]);
is($player->{name}, 'DOWNIE');
$player = Sport::Analytics::NHL::Merger::find_player({name => 'BRBRBR'}, $report->{teams}[0]);
is($player, undef, 'expected failure');
$player = Sport::Analytics::NHL::Merger::find_player({number => 99}, $report->{teams}[0]);
is($player, undef, 'expected failure');
$player = Sport::Analytics::NHL::Merger::find_player({_id => 8400000, number=> 99}, $report->{teams}[0]);
is_deeply($player, $player, 'missing player');
$player = Sport::Analytics::NHL::Merger::find_player({_id => 8471703,number=>8}, $report->{teams}[0]);
is($player->{number}, 8);



