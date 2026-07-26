#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Same::Boy;

plan tests => 11;

# Build a minimal, valid 32KB ROM-only cartridge whose program is an
# infinite loop. With the embedded open-source boot ROM this is enough to
# exercise CPU execution and PPU rendering.
sub minimal_rom {
    my $rom = "\x00" x 0x8000;
    substr($rom, 0x100, 4) = "\x00\xC3\x50\x01";  # nop; jp 0x150
    substr($rom, 0x150, 2) = "\x18\xFE";          # jr -2 (loop)
    substr($rom, 0x147, 1) = "\x00";              # MBC: ROM only
    substr($rom, 0x148, 1) = "\x00";              # ROM size: 32KB
    substr($rom, 0x149, 1) = "\x00";              # RAM size: none
    my $x = 0;
    $x = ($x - ord(substr($rom, $_, 1)) - 1) & 0xFF for 0x134 .. 0x14C;
    substr($rom, 0x14D, 1) = chr($x);             # header checksum
    return $rom;
}

for my $model (qw(dmg cgb)) {
    my $gb = Same::Boy->new(model => $model);
    isa_ok($gb, 'Same::Boy', "new(model => $model)");

    my ($w, $h) = $gb->dimensions;
    is("${w}x${h}", '160x144', "$model screen is 160x144");

    $gb->load_rom(\minimal_rom());

    my $cycles = 0;
    $cycles += $gb->run_frame for 1 .. 30;
    cmp_ok($cycles, '>', 0, "$model CPU executed cycles across 30 frames");

    my $px = $gb->pixels;
    is(length($px), $w * $h * 4, "$model framebuffer is w*h*4 bytes");

    my %colors;
    $colors{$_}++ for unpack 'L*', $px;
    cmp_ok(scalar keys %colors, '>', 1,
        "$model boot ROM rendered a non-blank frame");
}

# Input smoke test: pressing/releasing a button must not throw.
{
    my $gb = Same::Boy->new(model => 'cgb');
    $gb->load_rom(\minimal_rom());
    $gb->press('a')->run_frame;
    $gb->release('a')->run_frame;
    pass('press/release/run_frame round-trips without error');
}
