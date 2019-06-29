#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;

use Sport::Analytics::NHL::Vars qw($MONGO_DB);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Tools qw(:schedule);
use Sport::Analytics::NHL::Util qw(:file);
use Sport::Analytics::NHL::Scraper qw(crawl_injured_players);
use Sport::Analytics::NHL::Config qw(%TEAMS);

use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
test_env();
plan qw(no_plan);

my $db = Sport::Analytics::NHL::DB->new();
my $injuries = crawl_injured_players();
$db->get_collection('injuries')->drop();
$db->insert_injuries($injuries);
my @injuries_db = $db->get_collection('injuries')->find()->all();
for my $injury (@injuries_db) {
	ok($injury->{injury_status},         'status defined');
	ok($injury->{injury_type},           'type defined');
	like($injury->{_id},   qr/^\d+$/,     'id defined');
	like($injury->{begin}, qr/^\d{10}$/, 'begin defined');
	like($injury->{end},   qr/^\d{10}$/, 'end defined');
	is($injury->{end}, $injury->{begin}, 'injury begin/end the same');
	ok($injury->{player_name},           'name defined');
	ok($TEAMS{$injury->{team}},          'team defined');
}
sleep 2;
$db->insert_injuries([$injuries->[0]]);
my $injury_db = $db->get_collection('injuries')->find_one({_id => 1});
ok($injury_db->{end} > $injury_db->{begin}, 'injury extended');