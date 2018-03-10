# Copyright (C) 2013 MaxiM Basunov <maxim.basunov@gmail.com>
# All rights reserved.
#
# This program is free software; you may redistribute it and/or
# modify it under the same terms as Perl itself.

# $Id$

package Net::MRT;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::MRT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    @BGP_ORIGIN
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Net::MRT', $VERSION);

# Helper arrays
our @BGP_ORIGIN = ('IGP', 'EGP', 'INCOMPLETE');

# Preloaded methods go here.

1;
__END__

=head1 NAME

Net::MRT - Perl extension for decoding RFC6396 Multi-Threaded Routing Toolkit
(MRT) Routing Information Export Format

=head1 SYNOPSIS

Decode uncompressed MRT file:

    use Net::MRT;
    open(C, '<', 'file');
    binmode(C);
    while ($decode = Net::MRT::mrt_read_next(C))
    {
        do_something_useful($decode);
    }

In-memory download/decode:

    use LWP::Simple;
    use PerlIO::gzip;
    use Net::MRT;
    $LWP::Simple::ua->show_progress(1);
    $archive = get($url);
    open $mrt, "<:gzip", \$archive or die $!;
    while ($dd = Net::MRT::mrt_read_next($mrt))
    {
        do_something_useful($decode);
    }

B<Note:> In case of errors, reported message offset will be relative to Perl
internal buffer

Decode some binary message of known type/subtype:

    $hash = Net::MRT::mrt_decode_single($type, $subtype, $buffer);

Refer to t/ directory for a lot of examples, how each attribute decoded.

=head1 DESCRIPTION

L</Net::MRT::mrt_read_next> Decodes next message from filehandle

B<NOTE> Always set binary mode before call to mrt_read_next or got unexpected results.

L</Net::MRT::mrt_decode_single> Decodes message of specified type & subtype. See t/* for a lot of examples

TODO TODO

=head2 EXPORT

None by default.

=head1 Methods

=head2 Net::MRT::mrt_read_next

    {
        'timestamp' => 1222905597,
        'type' => X,
        'subtype' => Y,
        other decoded elements,
    };

In case of unsupported type/subtype an error message is returned in C<error>.

    {
        'timestamp' => Z,
        'type' => X,
        'subtype' => Y,
        'error' => 'Unsupported MRT type X subtype Y in message at N',
    };

TODO TODO

=head2 Net::MRT::mrt_decode_single

TODO TODO

=head2 Examples of decoded messages

=head3 Type=13 TABLE_DUMP_V2

=head4 Subtype=1 PEER_INDEX_TABLE

    {
        'peers' => [
                     '1' => {
                              'peer_ip' => '2001:db8::dead:beef',
                              'bgp_id' => '10.11.12.13',
                              'as' => 35243
                            },
                     '0' => {
                              'peer_ip' => '5.6.7.8',
                              'bgp_id' => '1.2.3.4',
                              'as' => 2164197642
                            }
                   ],
        'collector_bgp_id' => '1.2.3.4',
        'view_name' => 'testTEST',
    };

Peer index table decoded as HASH with peer's ARRAY allowing reference by peer's
index.

B<NOTE:> C<view_name> marked with UTF8 flag, but this field is optional by RFC.

=head4 Subtype=2 RIB_IPV4_UNICAST & Subtype=4 RIB_IPV6_UNICAST

    {
        'timestamp' => 1222905597,
        'type' => 13,
        'subtype' => 2,
        'prefix' => '10.0.0.0'
        'bits' => 8,
        'sequence' => 1,
        'entries' => [
                       { See Decoding of BGP attributes },
                       { See Decoding of BGP attributes },
                     ],
    };

B<NOTE:> C<type> C<subtype> C<timestamp> elements appended into HASH only while
stream decode using L<Net::MRT::mrt_read_next>.

=head3 Decoding of BGP attributes

BGP attributes decoded into the same HASHREF where decoded entry resides.

    {
      'peer_index' => 12,
      'originated_time' => 1220989283
      'ORIGIN' => 0,
      'NEXT_HOP' => '10.68.129.132',
      'AS_PATH' => [
                     65501,
                     65502,
                     [65503, 65504],
                     65505,
                   ],
      'unsupported7' => undef,
    }

C<peer_index> is a reference to L<PEER_INDEX_TABLE|/Subtype=1 PEER_INDEX_TABLE>.

The C<originated_time> contains the 4-octet time at which this prefix
was heard.  The value represents the time in seconds since 1 January
1970 00:00:00 UTC.

Unsupported (by L<Net::MRT>) attributes reported as 'unsupportedX' where X is a
BGP attribute code.

=head4 ORIGIN

    { 'ORIGIN' => 0 },
    $Net::MRT::BGP_ORIGIN[$entry->{'ORIGIN'}]

The ORIGIN decoded as integer. Additional helper array can be used to decode
into text representation.

=head4 AS_PATH

    {
      'AS_PATH' => [
                     65501,
                     65502,
                     65505,
                     [65503, 65504],
                   ],
    }

The AS_PATH decoded as array of elements. Each of element can be an AS_SEQUENCE
(single AS number) or AS_SET (array of AS numbers).

B<NOTE:> Multiple C<AS_PATH> attributes supported.

    - "The ability of a BGP speaker to include more than one instance of
    its own AS in the AS_PATH attribute for the purpose of inter-AS
    traffic engineering."

Determination of ORIGINATED AS is to skip trailing AS_SET and take single AS:

    foreach (reverse @{$_->{'AS_PATH'}}) {
        next if ref($_);
        print "Originated AS = $_\n";
        last;
    }

B<NOTE:> MRT TABLE_DATA_V2 AS_PATH contain four-octet AS numbers in AS_PATH
attribute. So, expect large numbers (> 65535).

L<RFC 6396: RIB ENTRIES|http://tools.ietf.org/html/rfc6396#section-4.3.4>

    - "All AS numbers in the AS_PATH attribute MUST be encoded as 4-byte AS numbers."

=head4 NEXT_HOP

IPv4 Next Hop:

    { 'NEXT_HOP' => [ '10.68.129.132' ], }

IPv6 Next Hop:

    { 'NEXT_HOP' => [ '2001:db8::1', 'fe80::dead:beef' ], }

B<MP_REACH_NLRI> carries global and link-local next-hop addresses. As result,
this attribute contains one or two entries in array.

In case, when entry will erroneously contain C<NEXT_HOP> and C<MP_REACH_NLRI>,
then resulting array will contain all of NEXT_HOP entries in one array.

=head4 MULTI_EXIT_DISC

    { 'MULTI_EXIT_DISC' => 2140, }

=head4 LOCAL_PREF

    { 'LOCAL_PREF' => 2140, }

=head4 ATOMIC_AGGREGATE

    { 'ATOMIC_AGGREGATE' => 1, }

Atomic aggregate is a flag. So, hash element with undefined value will be
present if this flag is set. Check for this flag using C<exists()> function:

    if (exists $_->{'ATOMIC_AGGREGATE'}) ...

=head4 AGGREGATOR

    { 'AGGREGATOR_AS' => 65501, 'AGGREGATOR_BGPID' => '10.12.14.1', }

Aggregator decoded into two elements C<AGGREGATOR_AS> & C<AGGREGATOR_BGPID>.
As per L</AS_PATH>, the C<AGGREGATOR_AS> also have 4 octets.

=head4 COMMUNITY

    { 'COMMUNITY' => [
        '1:2',
        '3:4',
    ], }

Communities decoded as array of communities (16 bit:16 bit)

=head4 MP_REACH_NLRI

Refer to L<NEXT_HOP> attribute.

B<NOTE:> The C<MP_REACH_NLRI> attribute can be decoded as per B<RFC4760> or
B<RFC6396>.

Due to recent changes in Quagga/RIPE RIS, the collected MRT data does not
follow RFC6396 and the C<MP_REACH_NLRI> should be decoded as described
in L<RFC4760|http://tools.ietf.org/html/rfc4760>

The C<$Net::MRT::USE_RFC4760> global variable control L<Net::MRT> behavior:

=over

=item *

C<$Net::MRT::USE_RFC4760 = 1;> - Decode as described in B<RFC4760>

=item *

C<$Net::MRT::USE_RFC4760 = undef;> - Decode as described in B<RFC6396>
(default behavior). Please note that only B<NEXT-HOP> will be decoded.

=item *

C<$Net::MRT::USE_RFC4760 = -1;> - Do not decode C<MP_REACH_NLRI> at all.

=back


=head1 SEE ALSO

L<http://tools.ietf.org/html/rfc6396>

L<http://www.ripe.net/data-tools/stats/ris/ris-raw-data>

L<http://www.quagga.net>

L<http://tools.ietf.org/html/rfc4760>

=head1 AUTHOR

MaxiM Basunov,  E<lt>maxim.basunov@gmail.comE<gt>

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 MaxiM Basunov <maxim.basunov@gmail.com>
All rights reserved.

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=cut
