#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

BEGIN {
    use_ok('Proc::BackOff');
}

can_ok( 'Proc::BackOff', qw |
    new
    delay
    success
    reset
    failure
    calculate_back_off
    max_timeout
    failure_count
    failure_start
    failure_time
    failure_over
    backOff_in_progress
|
);
