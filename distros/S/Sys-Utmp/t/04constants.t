#!/usr/bin/perl 

use strict;
use warnings;
use Test::More tests => 10;

use Sys::Utmp qw(:constants);

ok(defined ACCOUNTING,'ACCOUNTING Constant');
ok(defined BOOT_TIME, 'BOOT_TIME Constant');
ok(defined DEAD_PROCESS, 'DEAD_PROCESS Constant');
ok(defined EMPTY, 'EMPTY Constant');
ok(defined INIT_PROCESS, 'INIT_PROCESS Constant');
ok(defined LOGIN_PROCESS, 'LOGIN_PROCESS Constant');
ok(defined NEW_TIME, 'NEW_TIME Constant');
ok(defined OLD_TIME, 'OLD_TIME Constant');
ok(defined RUN_LVL, 'RUN_LVL Constant');
ok(defined USER_PROCESS, 'USER_PROCESS Constant');
