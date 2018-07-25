#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 4;

use Sport::Analytics::NHL::Merger;

ok(defined $Sport::Analytics::NHL::Merger::BOXSCORE, 'boxscore placeholder defined');
ok(defined $Sport::Analytics::NHL::Merger::CURRENT, 'current placeholder defined');
ok(defined $Sport::Analytics::NHL::Merger::PLAYER_RESOLVE_CACHE, 'p_r_c placeholder defined');

ok(defined &merge_report, 'merge report defined');

