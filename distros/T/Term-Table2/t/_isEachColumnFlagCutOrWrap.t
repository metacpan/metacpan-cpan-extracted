#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

is(_isEachColumnFlagCutOrWrap(0),       1, 'General flag for whole table');
is(_isEachColumnFlagCutOrWrap([0, 3]), '', 'Single flag for each column');

done_testing();