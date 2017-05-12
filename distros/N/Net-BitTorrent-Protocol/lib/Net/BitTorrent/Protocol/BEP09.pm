package Net::BitTorrent::Protocol::BEP09;
use strict;
use warnings;
our $VERSION = "1.5.3";
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use Exporter qw[];
*import = *import = *Exporter::import;
%EXPORT_TAGS = (
    build => [
        qw[build_metadata_request build_metadata_data build_metadata_reject]
    ],
    parse => [qw[ ]]    # XXX - None required
);
@EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;

#
sub build_metadata_request ($) {
    my ($index) = @_;
    return
        bencode({piece => $index,
                 msg_type => 0
                }
        );
}

sub build_metadata_data ($$) {
    my ($index, $data) = @_;
    return
        bencode({piece => $index,
            total_size=> length($data),
                 msg_type => 1
                }
        ) . $data;
}

sub build_metadata_reject ($) {
    my ($index) = @_;
    return
        bencode({piece => $index,
                 msg_type => 2
                }
        );
}

1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP09 - Packet Utilities for BEP09: The Extention for Peers to Send Metadata Files

=head1 Description

The purpose of this extension is to allow clients to join a swarm and complete
a download without the need of downloading a .torrent file first. This
extension instead allows clients to download the metadata from peers. It makes
it possible to support I<magnet links>, a link on a web page only containing
enough information to join the swarm (the info hash).

This metadata extiontion uses the
L<extention protocol|Net::BitTorrent::Protocol::BEP10> to advertise its
existence. It adds the C<ut_metadata> entry to the C<m> dictionary in the
extention header handshake message. It also adds C<metadata_size> to the
handshake message (not the C<m> dictionary) specifiying an integer value of
the number of bytes of the metadata.

=head1 Importing From Net::BitTorrent::Protocol::BEP09

By default, nothing is exported.

You may import any of the following or use one or more of these tag:

=over

=item C<:all>

Imports everything. If you're importing anything, this is probably what you
want.

=item C<:build>

Imports the functions which generate messages.

=back

Note that there are no parser functions as the packets generated for BEP09 are
simple bencoded hashes. Use the
L<bedecoder in BEP03|Net::BitTorrent::Protocol::BEP03::Bencode>.

=head1 Functions

This extention is very simple; there's a single request packet type and only
two possible reply packet types:

=over

=item C<build_metadata_request( $index )>

Generates an appropriate request for a subpiece of the torrent's metadata.

=item C<build_metadata_data( $index, $piece )>

Generates an appropriate reply to a
L<request query|/"build_metadata_request( $index )">.

=item C<build_metadata_reject( $index, $piece )>

Generates an appropriate reply to a
L<request query|/"build_metadata_request( $index )"> if the requested piece
is not available.

=back

=head1 Magnet URI Format

The magnet URI format is:

    magnet:?xt=urn:btih:<info-hash>&dn=<name>&tr=<tracker-url>

Where C<info-hash> is the infohash, hex encoded, for a total of C<40>
characters. For compatability with existing links in the wild, clients should
also support the C<32> character base32 encoded infohash.

=head1 See Also

=over

=item BEP 09: Extention for Peers to Send Metadata Files

http://bittorrent.org/beps/bep_0009.html

=back

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2010-2014 by Sanko Robinson <sanko@cpan.org>

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
