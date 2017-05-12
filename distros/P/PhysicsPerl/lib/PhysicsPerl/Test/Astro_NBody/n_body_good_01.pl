#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: '-0.169_075_16' >>>
# <<< EXECUTE_SUCCESS: '-0.169_016_44' >>>

# [[[ HEADER ]]]
use RPerl;
use strict;
use warnings;
our $VERSION = 0.002_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use PhysicsPerl::Astro::System;
use PhysicsPerl::Astro::SystemRenderer2D;
use Time::HiRes qw(time);

# [[[ OPERATIONS ]]]

my integer $time_step_max = 10_000;  # default
if (defined $ARGV[0]) { $time_step_max = string_to_integer($ARGV[0]); }  # user input, command-line argument
my number $delta_time = 0.01;

my boolean $enable_graphics = 0;  # default 
if (defined $ARGV[1]) { $enable_graphics = string_to_boolean($ARGV[1]); }  # user input, command-line argument
my integer $time_steps_per_frame = 50;

my number $time_start = time();

my PhysicsPerl::Astro::System $system = PhysicsPerl::Astro::System->new();
$system->init();
print 'start energy: ' . number_to_string($system->energy()) . "\n";

if ($enable_graphics) {
    my PhysicsPerl::Astro::SystemRenderer2D $renderer = PhysicsPerl::Astro::SystemRenderer2D->new();
    $renderer->init($system, $delta_time, $time_step_max, $time_steps_per_frame, $time_start);
    $renderer->render2d_video();
}
else {
    $system->advance_loop($delta_time, $time_step_max);  # 85 seconds; SSE 13 seconds
}

print 'end energy:   ' . number_to_string($system->energy()) . "\n";
my number $time_total = time() - $time_start;
print 'time total:   ' . $time_total . ' seconds' . "\n";
