package Protocol::IR::Proto::NECX2;
use strict;
use warnings;

our $VERSION = '1.0';

use parent 'Protocol::IR::Proto::NEC';

# NECx2 is the MakeHex NECx2.irp protocol: a 16-bit address with a half
# (4500/4500 us) header, repeating the entire frame. Single-frame timing
# is identical to NECx1; only the protocol name differs.
sub _protocol_name  { 'NECX2' }
sub _half_header    { 1 }
sub _inverted_subaddress_default { 0 }
sub _normalize_subaddress        { 0 }

use Protocol::IR::Code;

# Convert a NECX2 code to its SAMSUNG equivalent parameters.
# NECx2 device/subdevice are the bit-reversal of the Samsung address,
# and the NECx2 function is the bit-reversal of the Samsung command.
# Returns a hashref suitable for import_code('SAMSUNG', \%params).
sub as_samsung_params {
    my ($self, $code) = @_;
    my $addr = Protocol::IR::Code::reverse_byte($code->address & 0xFF);
    my $cmd  = Protocol::IR::Code::reverse_byte($code->command & 0xFF);
    return {
        address => $addr,
        command => $cmd,
    };
}

1;

=head1 NAME

Protocol::IR::Proto::NECX2 - NECx2 protocol handler (extended NEC, whole-frame repeat)

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # NECx2 is the framing used by Samsung TVs: half 4500/4500 us header
    # and a real 16-bit address (device + subdevice bytes).
    my $code = $converter->import_code('NECX2',
        { device => 7, subdevice => 7, command => 2 });

=head1 DESCRIPTION

The NECx2 protocol (MakeHex F<NECx2.irp>) transmits the same frame as
L<Protocol::IR::Proto::NECX1> -- half B<4500/4500 us> header, 16-bit address
(Default S=D) -- but repeats the B<entire> frame instead of a short
header+gap ditto. For a single frame the two are timing-identical, so this
class only changes the protocol name. Samsung TV IRDB files (for example)
label their codes C<NECx2>; a Samsung POWER row of device 7, subdevice 7,
function 2 packs to C<0x070702FD>, which matches the output of a reference
MakeHex build.

Like C<NECx1>, a single C<NECx2> frame cannot be told apart from
L<Protocol::IR::Proto::SAMSUNG> by timing alone; see L<Protocol::IR::Proto::NECX1> for
how L<Protocol::IR::Converter> resolves that. The name is preserved on the
by-name (CSV) import path.

=head1 METHODS

All methods are inherited from L<Protocol::IR::Proto::NEC>; only the protocol
name, header, and subaddress behavior differ, plus the following additional
method:

=head2 as_samsung_params

    my $params = $class->as_samsung_params($code);

Converts a NECX2 code to its L<Protocol::IR::Proto::SAMSUNG> equivalent
parameter hashref.  The NECX2 device byte is bit-reversed to produce the
Samsung address, and the function byte is bit-reversed to produce the
Samsung command.

The returned hashref is suitable for
C<< $converter->import_code('SAMSUNG', $params) >>.

Example:

    # NECX2 Samsung TV POWER: device=7, function=2
    #   -> SAMSUNG address=0xE0, command=0x40
    my $sam_params = Protocol::IR::Proto::NECX2->as_samsung_params($code);

This is used by L<Protocol::IR::Converter/cross_protocol> and is also
available for direct use when matching captures against IRDB entries.

=head1 CROSS-PROTOCOL MAPPING

NECX2 shares identical timing with L<Protocol::IR::Proto::SAMSUNG>: both use
a B<4500/4500 us> half header, B<560/1680 us> bit timing, 32 bits, per-byte
LSB-first.  They are distinguished only by the byte structure on the wire:
Samsung repeats the address byte and follows the command with its one's
complement (C<addr, addr, cmd, ~cmd>), while NECX2 carries a real subaddress
byte (C<device, subdevice, function, ~function>).

When a Samsung TV code is stored in IRDB as NECX2 (the common convention),
the Samsung address is the bit-reversal of the NECX2 device byte, and the
Samsung command is the bit-reversal of the function byte.  For example,
Samsung TV POWER is IRDB entry C<NECx2,7,7,2>: device 7 bit-reverses to
address 0xE0, function 2 bit-reverses to command 0x40.

Use L<Protocol::IR::Converter/cross_protocol> to convert between the two
automatically, or call C<as_samsung_params> directly.

=head1 SUPPORT

Source code: L<https://github.com/bwarden/perl-protocol-ir>

Bug reports and feature requests: L<https://github.com/bwarden/perl-protocol-ir/issues>

=head1 AUTHOR

Brett T. Warden <bwarden@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Brett T. Warden

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License version 2.1 as
published by the Free Software Foundation.
