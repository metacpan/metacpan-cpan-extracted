package TestROM;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(minimal_rom);

# Build a minimal, valid 32KB cartridge whose program is an infinite loop.
# %opt: mbc (0x147 value), ram (0x149 value) to request battery-backed RAM.
sub minimal_rom {
    my %opt = @_;
    my $rom = "\x00" x 0x8000;
    substr($rom, 0x100, 4) = "\x00\xC3\x50\x01";        # nop; jp 0x150
    substr($rom, 0x150, 2) = "\x18\xFE";                # jr -2 (loop)
    substr($rom, 0x147, 1) = chr($opt{mbc} // 0x00);    # cartridge type
    substr($rom, 0x148, 1) = "\x00";                    # ROM size: 32KB
    substr($rom, 0x149, 1) = chr($opt{ram} // 0x00);    # RAM size
    my $x = 0;
    $x = ($x - ord(substr($rom, $_, 1)) - 1) & 0xFF for 0x134 .. 0x14C;
    substr($rom, 0x14D, 1) = chr($x);                   # header checksum
    return $rom;
}

1;
