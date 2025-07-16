#!/usr/bin/env perl

use strict;
use warnings;
use Test::NoWarnings;

use Test::Most tests => 12;

BEGIN { use_ok('Readonly::Values::Months') }

cmp_ok($Readonly::Values::Months::JAN, '==', 1, 'Basic value test');
cmp_ok($JAN, '==', 1, 'Test value exports');
cmp_ok($months{'jan'}, '==', 1, 'Test hash exports');
cmp_ok($months{lc('Apr')}, '==', 4, 'Test April');

cmp_ok(scalar(@month_names), '==', 12, 'There are twelve months');
cmp_ok(scalar(@short_month_names), '==', 12, 'There are twelve short months');
cmp_ok(scalar(keys %month_names_to_short), '==', 12, 'There are twelve short months mapped');

cmp_ok($month_names[0], 'eq', 'january', 'month_names array looks sensible');
cmp_ok($short_month_names[0], 'eq', 'jan', 'short_month_names array looks sensible');

cmp_ok($month_names_to_short{'september'}, 'eq', 'sep', 'month_names_to_short looks sensible');
