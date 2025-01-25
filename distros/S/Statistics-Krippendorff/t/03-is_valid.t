#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Krippendorff;

use Test2::V0;
plan 7;

is 'Statistics::Krippendorff'->new(
    units => [{c1 => 'A', c2 => 'B'}, {c1 => 'C', c3 => 'D'}]
)->is_valid, bool(1), 'Valid';

is 'Statistics::Krippendorff'->new(
    units => [{c1 => 'A', c2 => 'B'}, {c1 => 'C', c3 => undef}]
)->is_valid, bool(0), 'Undef value';

is 'Statistics::Krippendorff'->new(
    units => [{c1 => 'A', c2 => 'B'}, {c1 => 'C'}]
)->is_valid, bool(0), 'Single coder';

is 'Statistics::Krippendorff'->new(
    units => [{c1 => 'A', c2 => 'B'}, {}]
)->is_valid, bool(0), 'Empty unit';

is 'Statistics::Krippendorff'->new(
    units => [['a', 'b'], ['c']]
)->is_valid, bool(0), 'Single coder array';

is 'Statistics::Krippendorff'->new(
    units => [['a', 'b'], []]
)->is_valid, bool(0), 'Empty unit array';

is 'Statistics::Krippendorff'->new(
    units => [['a', 'b'], [undef, 'a']]
)->is_valid, bool(0), 'Single value with undef array';
