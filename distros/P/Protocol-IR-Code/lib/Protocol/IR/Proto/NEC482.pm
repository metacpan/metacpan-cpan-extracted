package Protocol::IR::Proto::NEC482;
use strict;
use warnings;

our $VERSION = '1.1';

use parent 'Protocol::IR::Proto::NEC48';

# NEC482 is the 48-NEC2 variant: identical single-frame timing to 48-NEC1,
# only the repeat differs (the '2' variants re-transmit the whole frame
# instead of a short header+gap ditto frame). A single frame of either is
# timing-identical, so a timing decode labels both 48-NEC1; the name is
# preserved so repeat behavior survives conversion.
sub _protocol_name { '48-NEC2' }

1;

=head1 NAME

Protocol::IR::Proto::NEC482 - 48-NEC2 protocol handler (48-bit NEC, whole-frame repeat)

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    use Protocol::IR::Converter;

    my $converter = Protocol::IR::Converter->new();

    # 48-NEC2 is timing-identical to 48-NEC1 for a single frame; the name is
    # kept so repeat behavior survives conversion.
    my $code = $converter->import_code('48-NEC2',
        { address => 77, subaddress => 178, command => 222 });

=head1 DESCRIPTION

The C<48-NEC2> variant of L<Protocol::IR::Proto::NEC48> transmits an
identical single frame; only the repeat structure differs (it re-transmits
the whole frame rather than a short header+gap ditto frame). Because the
repeat is invisible to the single-frame decoders, a timing decode labels both
variants C<48-NEC1>; the C<48-NEC2> name is produced when a code is imported
by name (CSV, C<decode_params>, C<decode_raw>), which is the IRDB-to-wig
path.

=head1 METHODS

All methods are inherited from L<Protocol::IR::Proto::NEC48>; only the
protocol name differs.

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
