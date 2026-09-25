package Protocol::IR::Proto::NECX1;
use strict;
use warnings;

our $VERSION = '1.1';

use parent 'Protocol::IR::Proto::NEC';

# NECx1 is the MakeHex NECx1.irp protocol: a 16-bit address with a half
# (4500/4500 µs) header. The second address byte is a real byte (Default
# S=D), not an inversion, so it is never normalized to -1.
sub _protocol_name  { 'NECX1' }
sub _half_header    { 1 }
sub _inverted_subaddress_default { 0 }
sub _normalize_subaddress        { 0 }

1;

=encoding utf8

=head1 NAME

Protocol::IR::Proto::NECX1 - NECx1 protocol handler (extended NEC, half header)

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # NECx1 ("extended NEC") uses a half 4500/4500 µs header and a real
    # 16-bit address: the subaddress byte is the low half, not an
    # inversion of the address.
    my $code = $converter->import_code('NECX1',
        { device => 162, subdevice => 162, command => 1 });

=head1 DESCRIPTION

The NECx1 protocol (MakeHex F<NECx1.irp>) transmits the same 32-bit frame
layout as L<Protocol::IR::Proto::NEC> but with a half B<4500/4500 µs> header and a
B<16-bit address>: the second byte is the low half of the address (Default
S=D), so it is kept as a real byte and never normalized to C<-1> (see
L<Protocol::IR::Proto::NEC> for the full data layout and timing). This is the
framing IRDB files Samsung, Grundig, KAWA, and others label C<NECx1>.

The repeat frame is a short header+gap "ditto" frame, like NEC1. The
C<NECx2> variant (L<Protocol::IR::Proto::NECX2>) repeats the whole frame instead;
a single frame of either is timing-identical.

A NECx1 frame shares its 4500/4500 µs header with L<Protocol::IR::Proto::SAMSUNG>
(Samsung is IRDB's most common NECx2 user), so the two cannot be told apart
from timing alone. L<Protocol::IR::Converter> registers C<SAMSUNG> before C<NECX1>,
matching real-world Samsung captures; the C<NECX1> name is produced when a
code is imported by name (CSV, C<decode_params>, C<decode_raw>), the
IRDB-to-wig path. The data word is identical under either label.

=head1 METHODS

All methods are inherited from L<Protocol::IR::Proto::NEC>; only the protocol
name, header, and subaddress behavior differ.

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
