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
$report->set_event_extra_data();
my $event;

$Sport::Analytics::NHL::Merger::PLAYER_RESOLVE_CACHE = $report->{resolve_cache};
$event = Sport::Analytics::NHL::Merger::find_event({special => 1}, $report->{events}, 'XX');
is($event, -1, 'special ok');
$event = Sport::Analytics::NHL::Merger::find_event({player => 1}, $report->{events}, 'XX');
is($event, -1, 'Not PL, no player1 ok');
$event = Sport::Analytics::NHL::Merger::find_event({
	t => -1, period => 1, type => 'PSTR', ts => 0,
}, $report->{events}, 'PL');
is($event->{bsjs_id}, 51, 'event found');
$event = Sport::Analytics::NHL::Merger::find_event({
	t => -1, period => 1, type => 'GEND', ts => 0,
}, $report->{events}, 'PL');
is($event, -1, 'event expected not found');
$event = Sport::Analytics::NHL::Merger::find_event({
	t => -1, period => 1, type => 'STOP', ts => 0,
}, $report->{events}, 'PL');
is($event, -1, 'event expected not found');
$event = Sport::Analytics::NHL::Merger::find_event({
	t => -1, period => 3, type => 'STOP', ts => 3486, stopreason => '',
}, $report->{events}, 'PL');
is($event, -1, 'refined to nothing');
$event = Sport::Analytics::NHL::Merger::find_event({
	t => -1, period => 3, type => 'STOP', ts => 3486, stopreason => 'PUCK IN CROWD',
}, $report->{events}, 'PL');
is($event->{bsjs_id}, 673, 'refined to first event');
