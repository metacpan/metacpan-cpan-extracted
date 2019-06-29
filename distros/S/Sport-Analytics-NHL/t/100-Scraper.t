#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Scraper;

plan tests => 17;

ok(defined $Sport::Analytics::NHL::Scraper::SCHEDULE_JSON,     'schedule json template defined');
ok(defined $Sport::Analytics::NHL::Scraper::SCHEDULE_JSON_API, 'schedule json api template defined');
ok(defined $Sport::Analytics::NHL::Scraper::HTML_REPORT_URL,   'html report url template defined');
ok(defined $Sport::Analytics::NHL::Scraper::DEFAULT_RETRIES,   'default retries defined');

for my $game_file (@Sport::Analytics::NHL::Scraper::GAME_FILES) {
	like($game_file->{name}, qr/^\S\S$/, 'two letter doc name');
	is($game_file->{extension}, 'json', 'json extension special') if $game_file->{extension};
	isa_ok($game_file->{validate}, 'CODE', 'validate sub defined') if $game_file->{validate};
	like($game_file->{pattern}, qr/^http/, 'HTTP URL as pattern') if $game_file->{pattern};
}
