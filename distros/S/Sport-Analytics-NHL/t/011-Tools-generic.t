#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

plan tests => 16;

use Sport::Analytics::NHL::Tools qw(:generic);
use Sport::Analytics::NHL::Vars  qw($REPORTS_DIR);

is_deeply(
	Sport::Analytics::NHL::Tools::parse_nhl_game_id(2010020102),
	{ season => 2010, stage => 2, season_id => "0102", game_id => 201020102 },
	'nhl id parsed correctly',
);
is_deeply(
	Sport::Analytics::NHL::Tools::parse_our_game_id(201020102),
	{ season => 2010, stage => 2, season_id => "0102", game_id => 201020102 },
	'our id parsed correctly',
);

is(Sport::Analytics::NHL::Tools::get_season_from_date(20100202), 2009, 'season correct');
is(Sport::Analytics::NHL::Tools::get_season_from_date(20100902), 2010, 'season correct');

is(
	Sport::Analytics::NHL::Tools::get_schedule_json_file(2010),
	"$REPORTS_DIR/2010/schedule.json", 'season correct'
);
is(
	Sport::Analytics::NHL::Tools::get_schedule_json_file(2010, '/tmp'),
	'/tmp/2010/schedule.json', 'season correct'
);
is_deeply(
	[Sport::Analytics::NHL::Tools::get_start_stop_date(2010)],
	[qw(2010-09-02 2011-09-01)], 'start stop date correct',
);
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';
my $path = make_game_path(2010, 2, 102);
is($path, 't/tmp/data/2010/0002/0102', 'path created');
ok(-d $path, 'it is indeed a path');
$path = make_game_path(2010, 2, 102);
system(qw(rm -rf t/tmp/data));
$path = make_game_path(2010, 2, 102, 't/tmp/otherdata');
is($path, 't/tmp/otherdata/2010/0002/0102', 'path created');
ok(-d $path, 'it is indeed a path');
system(qw(rm -rf t/tmp/otherdata));

$path = 't/tmp/data/2010/0002/0102';
my $id = get_game_id_from_path($path);
is($id, 201020102, 'id correct');

is(resolve_team('Montreal Canadiens',1), 'MTL', 'Montreal resolved');
is(resolve_team('League',            1), 'NHL', 'League resolved');
is(resolve_team('TBL',               1), 'TBL', 'TBL resolved');
is(resolve_team('N.J',               1), 'NJD', 'N.J resolved');
