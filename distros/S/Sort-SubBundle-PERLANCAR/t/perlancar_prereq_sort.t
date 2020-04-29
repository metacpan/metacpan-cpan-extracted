#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'prereq_ala_perlancar',
    input     => [qw(warnings strict perl AbA ABc A)],
    output    => [qw/perl strict warnings A AbA ABc/],
    output_i  => [qw/perl strict warnings A AbA ABc/],
    output_ir => [qw/ABc AbA A warnings strict perl/],
);

done_testing;
