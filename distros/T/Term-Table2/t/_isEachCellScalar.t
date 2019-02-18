#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

is(_isEachCellScalar([[1, {}], [2, undef]]), '', 'Failure');
is(_isEachCellScalar([[1,  2], [3, 4, 5]]),   1, 'Success');

done_testing();