#!/usr/bin/env perl

use strict;
use warnings;
use Test::NoWarnings;

use Test::Most tests => 5;

BEGIN { use_ok('Readonly::Values::Months') }

cmp_ok($Readonly::Values::Months::JAN, '==', 1, 'Basic value test');
cmp_ok($JAN, '==', 1, 'Test value exports');
cmp_ok($months{'jan'}, '==', 1, 'Test hash exports');
