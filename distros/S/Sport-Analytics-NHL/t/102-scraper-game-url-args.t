#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
plan tests => 3;

use Sport::Analytics::NHL::Scraper;

my @args;
my $game = { season => 2011, stage => 2, season_id => 10 };
@args = Sport::Analytics::NHL::Scraper::get_game_url_args('BS', $game);
is_deeply(\@args, [2011020010], 'game url args correct for BS');
@args = Sport::Analytics::NHL::Scraper::get_game_url_args('PB', $game);
is_deeply(\@args, [2011,2012,2011020010], 'game url args correct for PB');
@args = Sport::Analytics::NHL::Scraper::get_game_url_args('RO', $game);
is_deeply(\@args, [2011,2012,'RO',2,10], 'game url args correct for RO');
