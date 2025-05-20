#!/usr/bin/env perl

use strict;
use warnings;
use Test::NoWarnings;

use Test::Most tests => 5;

BEGIN { use_ok('Readonly::Values::Syslog') }

cmp_ok($Readonly::Values::Syslog::ALERT, '==', 1, 'Basic value test');
cmp_ok($ALERT, '==', 1, 'Test value exports');
cmp_ok($syslog_values{'alert'}, '==', 1, 'Test hash exports');
