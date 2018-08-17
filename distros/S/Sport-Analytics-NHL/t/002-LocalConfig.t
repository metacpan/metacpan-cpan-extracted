#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

plan tests => 8;

use Sport::Analytics::NHL::LocalConfig;

ok(defined $CURRENT_SEASON, 'current season defined');
ok(defined $CURRENT_STAGE,  'current stage defined');

ok(defined $DATA_DIR, 'data directory defined');

ok(defined $MERGED_FILE,     'merged file name defined');
ok(defined $NORMALIZED_FILE, 'normalized file name defined');
ok(defined $NORMALIZED_JSON, 'normalized json name defined');
ok(defined $SUMMARIZED_FILE, 'summarized file name defined');

ok(defined $DEFAULT_PLAYERFILE_EXPIRATION, 'playerfile expiration ok');

