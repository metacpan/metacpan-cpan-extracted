#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;

use Sport::Analytics::NHL::Config qw(:seasons);
use Sport::Analytics::NHL;

use t::lib::Util;

if ($ENV{HOCKEYDB_NONET}) {
	plan skip_all => 'No network tests requested';
	exit;
}
plan qw(no_plan);

test_env();
$ENV{HOCKEYDB_REPORTS_DIR} = 't/tmp/data';
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';
system(qw(mkdir -p t/tmp/));
system(qw(cp -a t/data t/tmp/));
my $opts = {no_schedule_crawl => 1, no_database => 1, start_season => 2016, stop_season => 2017};
$ENV{MONGO_DB} = undef;
my $nhl = Sport::Analytics::NHL->new($opts);
my @got_games = $nhl->scrape_games($opts, 193020001, 201620001, 201720001);
for my $season (1930,2016,2017) {
	for my $doc (keys %FIRST_REPORT_SEASONS) {
		my $extension = $doc eq 'PB' || $doc eq 'BS' ? 'json' : 'html';
		my $path      = "$ENV{HOCKEYDB_REPORTS_DIR}/$season/0002/0001";
		my $file      = "$path/$doc.$extension";
		if ($FIRST_REPORT_SEASONS{$doc} > $season) {
			ok(! -f $file, 'no content no year');
			next;
		}
		ok(-d $path, "path $path created");
		ok(-f $file, "file $file downloaded");
		ok(-s $file > 10000, 'file size reasonable');
		@got_games = grep { $_ eq $file ? () : $_ } @got_games;
	}
}
ok(! @got_games, 'all files matched');
system(qw(rm -rf t/tmp/data));
