package Net::BitTorrent::Protocol::BEP06;
our $VERSION = "1.5.3";
use Carp qw[carp];
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use Exporter qw[];
*import = *import = *Exporter::import;
%EXPORT_TAGS = (
    build => [
        qw[ build_suggest build_allowed_fast build_reject
            build_have_all build_have_none ]
    ],
    parse => [
        qw[ parse_suggest parse_have_all parse_have_none
            parse_reject parse_allowed_fast ]
    ],
    types => [qw[ $SUGGEST $HAVE_ALL $HAVE_NONE $REJECT $ALLOWED_FAST ]],
    utils => [qw[generate_fast_set]]
);
@EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;
our $SUGGEST      = 13;
our $HAVE_ALL     = 14;
our $HAVE_NONE    = 15;
our $REJECT       = 16;
our $ALLOWED_FAST = 17;

sub build_suggest {
    my ($index) = @_;
    if ((!defined $index) || ($index !~ m[^\d+$])) {
        carp sprintf '%s::build_suggest() requires an index parameter',
            __PACKAGE__;
        return;
    }
    return pack('NcN', 5, 13, $index);
}
sub build_have_all  { pack('Nc', 1, 14); }
sub build_have_none { pack('Nc', 1, 15); }

sub build_reject {
    my ($index, $offset, $length) = @_;
    if ((!defined $index) || ($index !~ m[^\d+$])) {
        carp sprintf '%s::build_reject() requires an index parameter',
            __PACKAGE__;
        return;
    }
    if ((!defined $offset) || ($offset !~ m[^\d+$])) {
        carp sprintf '%s::build_reject() requires an offset parameter',
            __PACKAGE__;
        return;
    }
    if ((!defined $length) || ($length !~ m[^\d+$])) {
        carp sprintf '%s::build_reject() requires an length parameter',
            __PACKAGE__;
        return;
    }
    my $packed = pack('N3', $index, $offset, $length);
    return pack('Nca*', length($packed) + 1, 16, $packed);
}

sub build_allowed_fast {
    my ($index) = @_;
    if ((!defined $index) || ($index !~ m[^\d+$])) {
        carp sprintf
            '%s::build_allowed_fast() requires an index parameter',
            __PACKAGE__;
        return;
    }
    return pack('NcN', 5, 17, $index);
}

# Parsing functions
sub parse_suggest {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 1)) {
        return {error => 'Incorrect packet length for SUGGEST'};
    }
    return unpack('N', $packet);
}
sub parse_have_all  { return; }
sub parse_have_none { return; }

sub parse_reject {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 9)) {
        return {error =>
                    sprintf(
                       'Incorrect packet length for REJECT (%d requires >=9)',
                       length($packet || ''))
        };
    }
    return ([unpack('N3', $packet)]);
}

sub parse_allowed_fast {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 1)) {
        return {error => 'Incorrect packet length for FASTSET'};
    }
    return unpack('N', $packet);
}

#
sub generate_fast_set {
    my ($k, $sz, $infohash, $ip) = @_;
    my @a;
    my $x = pack('C3', (split(/\./, $ip))) . "\0" . $infohash;
    while (1) {
        require Digest::SHA;
        $x = Digest::SHA::sha1($x);
        for my $i (0 .. 4) {
            return @a if scalar @a == $k;
            my $index = hex(unpack('H*', substr($x, $i * 4, 4))) % $sz;
            push @a, $index if !grep { $_ == $index } @a;
        }
    }
    @a;
}

#
1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP06 - Packet Utilities for BEP06: Fast Extension

=head1 Synopsis

    use Net::BitTorrent::Protocol::BEP06 qw[all];
    my $index = parse_allowed_fast($data);

=head1 Description

The Fast Extension modifies the semantics of the
L<Request|Net::BitTorrent::Protocol::BEP03/"build_request ( $index, $offset, $length )">,
L<Choke|Net::BitTorrent::Protocol::BEP03/"build_choke ( )">,
L<Unchoke|Net::BitTorrent::Protocol::BEP03/"build_unchoke ( )">, and
L<Cancel|Net::BitTorrent::Protocol::BEP03/"build_cancel ( $index, $offset, $length )">,
and adds a L<Reject|/"build_reject ( $index, $offset, $length )"> Request.
Now, every request is guaranteed to result in I<exactly one> response which is
either the corresponding reject or corresponding piece message. Even when a
request is cancelled, the peer receiving the cancel should respond with either
the corresponding reject or the corresponding piece: requests that are being
processed are allowed to complete.

Choke no longer implicitly rejects all pending requests, thus eliminating some
race conditions which could cause pieces to be needlessly requested multiple
times.

=head1 Importing from Net::BitTorrent::Protocol::BEP06

There are four tags available for import. To get them all in one go, use the
C<:all> tag.

=over

=item C<:types>

Packet types

For more on what these packets actually mean, see the Fast Extension spec.
This is a list of the currently supported packet types.

=over

=item C<$SUGGEST>

=item C<$HAVE_ALL>

=item C<$HAVE_NONE>

=item C<$REJECT>

=item C<$ALLOWED_FAST>

=back

=item C<:build>

These create packets ready-to-send to remote peers. See
L<Building Functions|/"Building Functions">.

=item C<:parse>

These are used to parse unknown data into sensible packets. The same packet
types we can build, we can also parse. See
L<Parsing Functions|/"Parsing Functions">.

=item C<:utils>

Helpful functions listed in the section entitled
L<Utility Functions|/"Utility Functions">.

=back

=head1 Building Functions

=over

=item C<build_have_all( )>

Creates an advisory packet which claims you have all pieces and can seed.

You should send this rather than a bitfield of all true values.

=item C<build_have_none( )>

Creates an advisory packet which claims you have no data related to the
torrent.

=item C<build_suggest( $index )>

Creates an advisory message meaning "you might like to download this piece."
The intended usage is for 'super-seeding' without throughput reduction, to
avoid redundant downloads, and so that a seed which is disk I/O bound can
upload contiguous or identical pieces to avoid excessive disk seeks.

You should send this instead of a bitfield of nothing but null values.

=item C<build_reject ( $index, $offset, $length )>

Creates a packet which is used to notify a requesting peer that its request
will not be satisfied.

=item C<build_allowed_fast ( $index )>

Creates an advisory message which means "if you ask for this piece, I'll give
it to you even if you're choked."

=back

=head1 Parsing Functions

These are the parsing counterparts for the C<build_> functions.

When the packet is invalid, a hash reference is returned with a single key:
C<error>. The value is a string describing what went wrong.

Return values for valid packets are explained below.

=over

=item C<parse_have_all( $data )>

Returns an empty list. HAVE ALL packets do not contain a payload.

=item C<parse_have_none( $data )>

Returns an empty list. HAVE NONE packets do not contain a payload.

=item C<parse_suggest( $data )>

Returns an integer.

=item C<parse_reject( $data )>

Returns an array reference containing the C<$index>, C<$offset>, and
C<$length>.

=item C<parse_allowed_fast( $data )>

Returns an integer.

=back

=head1 Utility Functions

=over

=item C<generate_fast_set( $k, $sz, $infohash, $ip )>

Returns a list of integers. C<$k> is the number of pieces in the set, C<$sz>
is the number of pieces in the torrent, C<$infohash> is the packed infohash,
C<$ip> is the IPv4 (dotted quad) address of the peer this set will be
generated for.

    my $data = join '',
        map { build_allowed_fast($_) }
        generate_fast_set(7, 1313, "\xAA" x 20, '80.4.4.200');

=back

=head1 See Also

http://bittorrent.org/beps/bep_0006.html - Fast Extension

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
