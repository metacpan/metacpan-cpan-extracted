#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Tools qw(is_lead_changing_goal is_lead_swinging_goal);

plan tests => 6;

is(is_lead_changing_goal([0,0], 1), 1, 'lcg from tie');
is(is_lead_changing_goal([1,0], 1), 1, 'lcg into tie');
is(is_lead_changing_goal([1,0], 0), 0, 'not lcg extension');

is(is_lead_swinging_goal([0,0], 1, undef), 0,  'no lsg from start of game');
is(is_lead_swinging_goal([1,1], 1,     0), 1, 'lsg from tie with a different lead');
is(is_lead_swinging_goal([1,0], 0,     0), 0, 'not lsg extension');
