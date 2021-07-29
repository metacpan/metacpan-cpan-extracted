#!/usr/bin/env perl

use Test2::V0;
use TCOD;

my $context = TCOD::Context->new(
    columns => 100,
    rows    => 100,
    sdl_window_flags => 8, # Hidden window
) or skip_all TCOD::get_error;

ok $context;

done_testing;
