#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 2;

use Sport::Analytics::NHL::PenaltyAnalyzer;

ok(defined &analyze_game_penalties, 'analyze penalties defined');
ok(defined &set_strengths, 'set strengths defined');
