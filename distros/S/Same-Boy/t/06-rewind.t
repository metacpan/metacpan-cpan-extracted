#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Same::Boy;
use TestROM qw(minimal_rom);

plan tests => 4;

my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());

isa_ok($gb->set_rewind_length(5), 'Same::Boy', 'set_rewind_length chains');

# Rewind snapshots are pushed automatically as frames run.
$gb->run_frame for 1 .. 120;

my $popped = $gb->rewind;
ok($popped, 'rewind restores a previous state after running frames');

# Clock multiplier / turbo are smoke-tested for non-throwing behaviour.
isa_ok($gb->set_clock_multiplier(2.0), 'Same::Boy', 'set_clock_multiplier chains');
isa_ok($gb->set_turbo(1, 0), 'Same::Boy', 'set_turbo chains');
