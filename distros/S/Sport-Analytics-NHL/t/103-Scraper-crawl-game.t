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
plan tests => 64;

use t::lib::Util;

test_env();
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';
use Sport::Analytics::NHL::Config qw(:seasons);
use Sport::Analytics::NHL::Tools qw(:path);
use Sport::Analytics::NHL::Scraper qw(crawl_game);
my @games = (
	{ season => 2011, stage => 2, season_id => 10 },
	{ season => 2001, stage => 2, season_id => 10 },
	{ season => 1969, stage => 2, season_id => 10 },
	{ season => 1930, stage => 2, season_id => 10 },
);
use Data::Dumper;
for my $game (@games) {
	my $contents = crawl_game($game);
	for my $doc (keys %FIRST_REPORT_SEASONS) {
		if ($FIRST_REPORT_SEASONS{$doc} > $game->{season}) {
			ok(!$contents->{$doc}, 'no content no year');
			next;
		}
		ok(length($contents->{$doc}{content}) > 10000, 'considerably large report');
		my $path = make_game_path($game->{season}, $game->{stage}, $game->{season_id});
		ok(-d $path, 'path created');
		my $extension = $doc eq 'PB' || $doc eq 'BS' ? 'json' : 'html';
		ok(-f "$path/$doc.$extension", 'file downloaded');
		ok(-s "$path/$doc.$extension" > length($contents->{$doc}{content}) - 30, 'file size preserved');
	}
}
system(qw(rm -rf t/tmp/data));


