#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 4;

use Sport::Analytics::NHL::Normalizer;

ok(%Sport::Analytics::NHL::Normalizer::EVENT_PRECEDENCE, 'event precedence defined');
ok(%Sport::Analytics::NHL::Normalizer::EVENT_TYPE_TO_STAT, 'event type to stat defined');

ok(defined &summarize, 'summarize defined');
ok(defined &normalize_boxscore, 'normalize boxscore defined');

