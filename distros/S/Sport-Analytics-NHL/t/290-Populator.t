#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 2;

use Sport::Analytics::NHL::Populator;

ok(defined &populate_injured_players, 'populate_injured_players defined');
ok(defined &populate_db, 'populate db defined');

