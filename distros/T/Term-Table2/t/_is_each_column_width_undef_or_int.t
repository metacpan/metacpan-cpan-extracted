#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

is(_is_each_column_width_undef_or_int(),                 1, 'General width for whole table');
is(_is_each_column_width_undef_or_int([3, undef, 'a']), '', 'Single width for each column');

done_testing();