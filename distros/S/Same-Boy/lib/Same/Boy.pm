package Same::Boy;

use 5.008003;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.02';

# Optional symbolic exports for button masks (defined in XS; see the BOOT
# block in Boy.xs).
our @EXPORT_OK = qw(
    KEY_RIGHT KEY_LEFT KEY_UP KEY_DOWN KEY_A KEY_B KEY_SELECT KEY_START
);

require XSLoader;
XSLoader::load('Same::Boy', $VERSION);

1;

__END__

=head1 NAME

Same::Boy - Game Boy and Game Boy Color emulator (SameBoy Core) for Perl

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Same::Boy;

    my $gb = Same::Boy->new(
        model       => 'cgb',
        rom         => 'game.gbc',
        sample_rate => 44100,
    );

    for (1 .. 60) {
        $gb->run_frame;
    }

    my ($w, $h) = $gb->dimensions;     # 160, 144
    my $frame   = $gb->pixels;         # packed 0x00RRGGBB words
    my $audio   = $gb->samples;        # interleaved s16 L,R

    $gb->press('a')->run_frame;
    $gb->release('a');

    # persistence
    my $sram  = $gb->save_battery;     # cartridge save RAM
    my $state = $gb->save_state;       # full snapshot
    $gb->load_state($state);

=head1 DESCRIPTION

Same::Boy wraps the C<Core> of L<SameBoy|https://github.com/LIJI32/SameBoy>,
a highly accurate Game Boy and Game Boy Color emulator, and exposes a Perl
API for loading ROMs, stepping frames, reading video and audio, sending
input, applying cheats, and saving/restoring state.

The SameBoy Core is vendored and compiled into the extension; there are no
external library dependencies. SameBoy's own MIT-licensed open-source boot
ROMs are embedded, so the emulator boots out of the box with no copyrighted
files and no build time toolchain.

=head1 CONSTRUCTOR

=head2 new(%args)

    my $gb = Same::Boy->new(model => 'cgb', rom => 'game.gbc');

Options: C<model> (one of C<dmg>, C<mgb>, C<sgb>, C<sgb2>, C<cgb>; default
C<cgb>), C<rom> and C<boot_rom> (a path or a scalar reference of bytes), and
C<sample_rate> (enable audio at the given rate in Hz).

=head1 EXECUTION

=head2 run_frame

Run until the next V-Blank (one frame). Returns cycles executed.

=head2 run

Run a single Core step. Returns cycles executed.

=head2 reset

Reset the console.

=head2 set_clock_multiplier($multiplier)

Scale emulation speed (e.g. C<2.0> for double speed).

=head2 set_turbo($on, $no_frame_skip)

Enable/disable turbo mode.

=head2 set_rtc_mode($mode)

Set real-time-clock behaviour for RTC cartridges (MBC3): C<sync_to_host> or
C<accurate>.

=head1 INTROSPECTION

=head2 model

The model string passed to the constructor.

=head2 is_cgb / is_sgb

Booleans for the emulated hardware family.

=head2 rom_title

The cartridge's internal title (up to 16 chars).

=head2 rom_crc32

CRC-32 of the loaded ROM.

=head1 VIDEO

=head2 dimensions

Return C<($width, $height)> in pixels.

=head2 pixels

The current framebuffer: a packed string of native-endian C<uint32> words
in C<0x00RRGGBB> form, C<$width * $height> of them.

=head2 pixels_rgba

The current framebuffer as tightly-packed C<R,G,B,A> bytes (alpha always
C<255>), C<$width * $height * 4> of them. Ready to drop into a JavaScript
C<ImageData> buffer for canvas rendering.

=head2 set_color_correction($mode)

One of C<disabled>, C<correct_curves>, C<modern_balanced>,
C<modern_boost_contrast>, C<reduce_contrast>, C<low_contrast>,
C<modern_accurate>.

=head2 set_dmg_palette($name)

For monochrome models, choose a built-in palette: C<grey>, C<dmg>, C<mgb>,
or C<gbl>.

=head1 AUDIO

=head2 set_sample_rate($hz)

Enable audio capture at C<$hz> (0 disables).

=head2 set_highpass_filter($mode)

One of C<off>, C<accurate>, C<remove_dc_offset>.

=head2 samples

Return and clear captured audio as interleaved signed 16-bit little-endian
left/right pairs. Call after C<run_frame>.

=head1 INPUT

=head2 press($button) / release($button)

C<$button> is one of C<up>, C<down>, C<left>, C<right>, C<a>, C<b>, C<start>,
C<select>.

=head2 press_for_player / release_for_player($button, $player)

As above for SGB multiplayer (C<$player> from 0).

=head2 set_key_mask($mask)

Set all buttons at once from an OR of the exportable C<KEY_*> constants.

=head1 PERSISTENCE

=head2 save_battery / load_battery($src)

Cartridge battery-backed save RAM as bytes. C<save_battery> returns undef if
the cartridge has none. C<load_battery> accepts a path or scalar ref.

=head2 save_battery_to_file($path) / load_battery_from_file($path)

=head2 save_state / load_state($src)

Full emulator snapshot (SameBoy BESS format). C<load_state> croaks on error.

=head2 save_state_to_file($path) / load_state_from_file($path)

=head1 REWIND

=head2 set_rewind_length($seconds)

Allocate a rewind buffer of the given duration (0 disables).

=head2 rewind

Step back one rewind slot; returns true if a previous state was restored.

=head1 CHEATS

=head2 import_cheat($code, %opts)

Import a Game Genie or GameShark code. Options: C<description>, C<enabled>
(default true). Returns true on success.

=head2 set_cheats_enabled($bool) / cheats_enabled

=head2 remove_all_cheats

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 ACKNOWLEDGEMENTS

Emulation Core by Lior Halphon (SameBoy), used under the Expat (MIT)
license. See F<LICENSE.SameBoy>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
