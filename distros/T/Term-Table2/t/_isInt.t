#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

is(_isInt(1),    1, 'Integer');
is(_isInt({}),  '', 'Not a scalar');
is(_isInt(1.2), '', 'Float');
is(_isInt(''),  '', 'Empty string');

done_testing();