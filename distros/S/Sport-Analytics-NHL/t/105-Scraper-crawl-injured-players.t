#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

if ($ENV{HOCKEYDB_NONET}) {
	plan skip_all => 'No network connection requested';
	exit;
}
plan qw(no_plan);
use t::lib::Util;
$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';
test_env();

use Sport::Analytics::NHL::Util qw(:file :debug);
use Sport::Analytics::NHL::Scraper qw(crawl_injured_players);
use Sport::Analytics::NHL::Config qw(%TEAMS);

my $injured = crawl_injured_players();
for my $injury (@{$injured}) {
	ok($injury->{injury_status}, 'status defined');
	ok($injury->{injury_type},   'type defined');
	ok($injury->{player_name},   'name defined');
	ok($TEAMS{$injury->{team}},  'team defined');
}