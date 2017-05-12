package Net::BitTorrent::Protocol::BEP10;
our $VERSION = "1.5.3";
use Carp qw[carp];
use Net::BitTorrent::Protocol::BEP03::Bencode qw[:all];
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use Exporter qw[];
*import = *import = *Exporter::import;
%EXPORT_TAGS = (build => [qw[ build_extended ]],
                parse => [qw[ parse_extended ]],
                types => [qw[ $EXTENDED ]]
);
@EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;

# Type
our $EXTENDED = 20;

# Build function
sub build_extended ($$) {
    my ($msgID, $data) = @_;
    if ((!defined $msgID) || ($msgID !~ m[^\d+$])) {
        carp sprintf
            '%s::build_extended() requires a message id parameter',
            __PACKAGE__;
        return;
    }
    if ((!$data) || (ref($data) ne 'HASH')) {
        carp sprintf '%s::build_extended() requires a payload', __PACKAGE__;
        return;
    }
    my $packet = pack('ca*', $msgID, bencode($data));
    return pack('Nca*', length($packet) + 1, 20, $packet);
}

# Parsing function
sub parse_extended ($) {
    my ($packet) = @_;
    if ((!$packet) || (!length($packet))) { return; }
    my ($id, $payload) = unpack('ca*', $packet);
    return ([$id, scalar bdecode($payload)]);
}
1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP23 - Packet Utilities for BEP10: Extension Protocol

=head1 Synopsis

    use Net::BitTorrent::Protocol::BEP10 qw[all];
    my $index = build_extended(
                              build_extended(
                                  0,
                                  {m => {'ut_pex' => 1, "\xC2\xB5T_PEX" => 2},
                                   p => 30,
                                   reqq   => 30,
                                   v      => "Net::BitTorrent r0.30",
                                   yourip => "\x7F\0\0\1",
                                  }
                              )
    );

=head1 Description

The intention of this protocol is to provide a simple and thin transport for
extensions to the bittorrent protocol. Supporting this protocol makes it easy
to add new extensions without interfering with the standard BitTorrent
protocol or clients that don't support this extension or the one you want to
add.

=head1 Importing from Net::BitTorrent::Protocol::BEP10

There are three tags available for import. To get them all in one go, use the
C<:all> tag.

=over

=item C<:types>

Packet types

For more on what these packets actually mean, see the Extension Protocol spec.
This is a list of the currently supported packet types.

=over

=item C<$EXTENDED>

=back

=item C<:build>

These create packets ready-to-send to remote peers. See
L<Building Functions|/"Building Functions">.

=item C<:parse>

These are used to parse unknown data into sensible packets. The same packet
types we can build, we can also parse. See
L<Parsing Functions|/"Parsing Functions">.

=back

=head1 Building Functions

=over

=item C<build_extended ( $msgID, $data )>

Creates an extended protocol packet.

C<$msgID> should be C<0> if you are creating a handshake packet, C<< >0 >> if
an extended message as specified by the handshake is being created.

C<$data> should be a HashRef of appropriate data.

=back

=head1 Parsing Functions

These are the parsing counterparts for the C<build_> functions.

When the packet is invalid, a hash reference is returned with a single key:
C<error>. The value is a string describing what went wrong.

Return values for valid packets are explained below.

=over

=item C<parse_extended( $data )>

Returns an integer ID and a HashRef containing the packet's payload.

=back

=head1 See Also

http://bittorrent.org/beps/bep_0010.html - Fast Extension

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2012 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=cut
