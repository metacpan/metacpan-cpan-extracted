#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use File::Temp ();
use Test::More;
use Same::Boy;
use TestROM qw(minimal_rom);

plan tests => 9;

# ---- save state round-trip + determinism --------------------------------
{
    my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());
    $gb->run_frame for 1 .. 20;

    my $state = $gb->save_state;
    cmp_ok(length($state), '>', 0, 'save_state returns bytes');

    # Advance, snapshot the future, then rewind via load_state and re-run:
    # deterministic emulation must reproduce the exact same frame.
    $gb->run_frame for 1 .. 10;
    my $future = $gb->pixels;

    $gb->load_state($state);
    $gb->run_frame for 1 .. 10;
    my $again = $gb->pixels;

    is($again, $future, 'load_state + re-run is deterministic');
}

# ---- save state to/from file --------------------------------------------
# pixels() reflects the last rendered frame, so both sides must run frames
# after the load point to produce a comparable image.
{
    my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());
    $gb->run_frame for 1 .. 15;

    my $tmp = File::Temp->new(SUFFIX => '.state');
    $gb->save_state_to_file("$tmp");
    ok(-s "$tmp", 'save_state_to_file writes a non-empty file');

    # original continues from the saved point
    $gb->run_frame for 1 .. 5;
    my $expect = $gb->pixels;

    my $gb2 = Same::Boy->new(model => 'cgb', rom => \minimal_rom());
    $gb2->load_state_from_file("$tmp");
    $gb2->run_frame for 1 .. 5;
    is($gb2->pixels, $expect, 'load_state_from_file + re-run restores the frame');
}

# ---- battery-backed save RAM --------------------------------------------
{
    # MBC5 + RAM + BATTERY (0x1B), 8KB RAM (0x02).
    my $rom = minimal_rom(mbc => 0x1B, ram => 0x02);
    my $gb  = Same::Boy->new(model => 'cgb', rom => \$rom);
    $gb->run_frame for 1 .. 5;

    my $sram = $gb->save_battery;
    ok(defined $sram, 'save_battery returns data for a RAM cartridge');
    is(length($sram), 8192, 'battery RAM is 8KB');

    my $tmp = File::Temp->new(SUFFIX => '.sav');
    $gb->save_battery_to_file("$tmp");
    ok(-e "$tmp", 'save_battery_to_file writes a file');

    my $gb2 = Same::Boy->new(model => 'cgb', rom => \$rom);
    isa_ok($gb2->load_battery_from_file("$tmp"), 'Same::Boy',
        'load_battery_from_file chains');
}

# ---- ROM-only cartridge has no battery ----------------------------------
{
    my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());
    is($gb->save_battery, undef, 'ROM-only cartridge has no battery RAM');
}
