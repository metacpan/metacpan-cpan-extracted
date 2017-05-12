#!/usr/bin/perl 

use strict;
use warnings;

use Sys::Utmp qw(:fields);
use Test::More tests => 7;

ok(defined UT_USER, 'UT_USER field');
ok(defined UT_ID, 'UT_ID field');
ok(defined UT_LINE, 'UT_LINE field');
ok(defined UT_PID, 'UT_PID field');
ok(defined UT_TYPE, 'UT_TYPE field');
ok(defined UT_HOST, 'UT_HOST field');
ok(defined UT_TIME, 'UT_TIME field');
