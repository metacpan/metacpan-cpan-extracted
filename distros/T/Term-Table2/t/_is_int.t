#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

is(_is_int(1),    1, 'Integer');
is(_is_int({}),  '', 'Not a scalar');
is(_is_int(1.2), '', 'Float');
is(_is_int(''),  '', 'Empty string');

done_testing();