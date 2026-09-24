package Protocol::IR::Proto::NEC2;
use strict;
use warnings;

our $VERSION = '1.0';

use parent 'Protocol::IR::Proto::NEC';

# NEC2 is the MakeHex nec2.irp protocol: 'Like NEC1, but repeats entire
# pattern'. For a single frame its timing and data layout are identical to
# NEC1 (full 9000/4500 us header, Default S=~D), so this class only changes
# the protocol name. The repeat difference is invisible to the single-frame
# decoders; preserving the name keeps the whole-frame repeat semantics
# through conversions.
sub _protocol_name { 'NEC2' }

1;

=head1 NAME

Protocol::IR::Proto::NEC2 - NEC2 protocol handler (repeats the whole frame)

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # NEC2 differs from NEC1 only in its repeat behavior: while NEC1
    # repeats a short header+gap "ditto" frame, NEC2 re-transmits the
    # entire 32-bit frame. A single NEC2 frame is timing-identical to a
    # NEC1 frame.
    my $code = $converter->import_code('NEC2',
        { device => 26, subdevice => 232, command => 5 });

=head1 DESCRIPTION

The NEC2 protocol (MakeHex F<nec2.irp>) transmits the same 32-bit frame as
L<Protocol::IR::Proto::NEC> with the same full 9000/4500 us header and the same
"Default S=~D" subaddress rule. The only difference from NEC1 is the repeat
frame: NEC1 repeats a short header+gap, NEC2 repeats the whole data frame.
That difference is not observable in any single frame, so the timing
decoders treat NEC1 and NEC2 identically (see L<Protocol::IR::Proto::NEC> for the
data layout and timing). This class exists so that codes imported under the
IRDB name C<NEC2> keep that identity and its repeat semantics.

Because a single NEC2 frame is indistinguishable from a NEC1 frame, the
C<decode_timing> decoder of L<Protocol::IR::Proto::NEC> (registered first) matches
it in L<Protocol::IR::Converter>; the C<NEC2> name is only produced when a code is
imported by name (CSV, C<decode_params>, C<decode_raw>), which is the
IRDB-to-wig path this distribution is built around.

=head1 METHODS

All methods are inherited from L<Protocol::IR::Proto::NEC>; only the protocol name
differs.

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
