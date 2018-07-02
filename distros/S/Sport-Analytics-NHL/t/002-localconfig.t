#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

plan tests => 3;

use Sport::Analytics::NHL::LocalConfig;

ok(defined $CURRENT_SEASON, 'current season defined');
ok(defined $CURRENT_STAGE,  'current stage defined');

ok(defined $DATA_DIR, 'data directory defined');
