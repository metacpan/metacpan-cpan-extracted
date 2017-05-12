#!/usr/bin/env perl

# n-Body, Program Source Code, Perl Implementation #3
# Calculate & Display Motion Of Heavenly Bodies
# The Open Benchmarks Group
# http://openbenchmarks.org

# Contributed In Java By Mark C. Lewis
# Modified Slightly In Java By Chad Whipkey
# Converted To Perl By Will Braswell

# $ ./script/demo/n_body.pl 50000000
# start energy: -0.169_075_163_828_524
# end energy:   -0.169_059_906_816_626
# time total:   3255.33442401886 seconds
# $ rperl lib/PhysicsPerl/Astro/System.pm
# $ ./script/demo/n_body.pl 50000000
# start energy: -0.169_075_163_828_524
# end energy:   -0.169_059_906_817_754
# time total:   85.7338771820068 seconds

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: '-0.169_075_16' >>>
# <<< EXECUTE_SUCCESS: '-0.169_059_90' >>>

# [[[ HEADER ]]]
use RPerl;
use strict;
use warnings;
our $VERSION = 0.001_200;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use PhysicsPerl::Astro::System;
use PhysicsPerl::Astro::SystemRenderer2D;
use Time::HiRes qw(time);

# [[[ OPERATIONS ]]]

my integer $time_step_max = 50_000_000;  # default
if (defined $ARGV[0]) { $time_step_max = string_to_integer($ARGV[0]); }  # user input, command-line argument
my number $delta_time = 0.01;

my boolean $enable_graphics = 1;  # default 
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
