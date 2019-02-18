#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

is(_areAllRowsOfEqualLength([[1, 2], [3]]), '', 'Executed');

done_testing();