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
plan tests => 31;

use t::lib::Util;

test_env();
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';

use Sport::Analytics::NHL::Util qw(:file);
use Sport::Analytics::NHL::Scraper qw(crawl_player);

use JSON;

my $file;
$file = crawl_player(7448208);

is($file, undef, 'missing player detected');

$file = crawl_player(8448208);
ok(-f $file, 'file crawled');
my $json = decode_json(read_file($file));

is($json->{draftyear}, 1990,  'draftyear ok');
is($json->{draftteam}, 'PIT', 'draftteam ok');
is($json->{round},     1,     'draftround ok');
is($json->{undrafted}, 0,     'undrafted ok');
is($json->{pick},      5,     'pick correct');

is($json->{id}, 8448208, 'id correct');
is($json->{rookie},    0, 'rookie correct');

isa_ok($json->{stats}, 'ARRAY', 'array of stats');

$file = crawl_player(8448321);
ok(-f $file, 'file crawled');
$json = decode_json(read_file($file));

is($json->{draftyear}, undef, 'draftyear ok');
is($json->{draftteam}, undef, 'draftteam ok');
is($json->{round},     undef, 'draftround ok');
is($json->{undrafted}, 1,     'undrafted ok');
is($json->{pick},      300,   'pick correct');

is($json->{id}, 8448321, 'id correct');
is($json->{rookie},    0, 'rookie correct');

isa_ok($json->{stats}, 'ARRAY', 'array of stats');
$file = crawl_player(8470794);
ok(-f $file, 'file crawled');
$json = decode_json(read_file($file));

is($json->{draftyear}, 2003, 'draftyear ok');
is($json->{draftteam}, 'SJS', 'draftteam ok');
is($json->{round},     7, 'draftround ok');
is($json->{undrafted}, 0,     'undrafted ok');
is($json->{pick},      205,   'pick correct');

is($json->{id}, 8470794, 'id correct');
is($json->{rookie},    0, 'rookie correct');
is($json->{active},    1, 'active correct');

isa_ok($json->{stats}, 'ARRAY', 'array of stats');
isa_ok($json->{currentTeam}, 'HASH', 'hash for a team');
$Sport::Analytics::NHL::Scraper::SUPP_PLAYER_URL = undef;

$file = crawl_player(8470794, {force => 1});

my $json2 = decode_json(read_file($file));

is_deeply($json, $json2, 'existing file used without SUPP url');

END {
	system(qw(rm -rf t/tmp/data));
}
