# Paranoid::Network::IPv6 -- IPv6-specific network functions
#
# $Id: lib/Paranoid/Network/IPv6.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
#
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>,
#
# subject to the following additional term:  No trademark rights to
# "Paranoid" have been or are conveyed under any of the above licenses.
# However, "Paranoid" may be used fairly to describe this unmodified
# software, in good faith, but not as a trademark.
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Network::IPv6;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Network::Socket;

my @base      = qw(ipv6NetConvert ipv6NetPacked ipv6NetIntersect);
my @constants = qw(MAXIPV6CIDR IPV6REGEX IPV6CIDRRGX IPV6BASE IPV6BRDCST
    IPV6MASK);
my @ipv6sort = qw(ipv6StrSort ipv6PackedSort ipv6NumSort);

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );
@EXPORT      = @base;
@EXPORT_OK   = ( @base, @constants, @ipv6sort );
%EXPORT_TAGS = (
    all       => [@EXPORT_OK],
    base      => [@base],
    constants => [@constants],
    ipv6Sort  => [@ipv6sort],
    );

use constant MAXIPV6CIDR => 128;
use constant IPV6REGEX   => qr/
                            :(?::[abcdef\d]{1,4}){1,7}                   | 
                            \b[abcdef\d]{1,4}(?:::?[abcdef\d]{1,4}){1,7} | 
                            (?:\b[abcdef\d]{1,4}:){1,7}: 
                            /six;
use constant IPV6CIDRRGX =>
    qr#@{[ IPV6REGEX ]}/(?:1(?:[01]\d|2[0-8])|\d\d?)#s;
use constant IPV6BASE   => 0;
use constant IPV6BRDCST => 1;
use constant IPV6MASK   => 2;
use constant CHUNKMASK  => 0xffffffff;
use constant CHUNK      => 32;
use constant IPV6CHUNKS => 4;
use constant IPV6LENGTH => 16;

#####################################################################
#
# Module code follows
#
#####################################################################

sub ipv6NetConvert {

    # Purpose:  Takes a string representation of an IPv6 network
    #           address and returns a list of lists containing
    #           the binary network address, broadcast address,
    #           and netmask, each broken into 32bit chunks.
    #           Also allows for a plain IP being passed, in which
    #           case it only returns the binary IP.
    # Returns:  Array, empty on errors
    # Usage:    @network = ipv6NetConvert($netAddr);

    my $netAddr = shift;
    my ( $bnet, $bmask, $t, @tmp, @rv );

    pdebug( 'entering w/%s', PDLEVEL1, $netAddr );
    pIn();

    if ( has_ipv6() or $] >= 5.012 ) {

        # Extract net address, mask
        if ( defined $netAddr ) {
            ($t) =
                ( $netAddr =~ m#^(@{[ IPV6CIDRRGX ]}|@{[ IPV6REGEX ]})$#s )
                [0];
            ( $bnet, $bmask ) = split m#/#s, $t if defined $t;
        }

        if ( defined $bnet and length $bnet ) {

            # First, convert $bnet to see if we have a valid IP address
            $bnet = [ unpack 'NNNN', inet_pton( AF_INET6(), $bnet ) ];

            if ( defined $bnet and length $bnet ) {

                # Save our network address
                push @rv, $bnet;

                if ( defined $bmask and length $bmask ) {

                    # Convert netmask
                    if ( $bmask <= MAXIPV6CIDR ) {

                        # Add the mask in 32-bit chunks
                        @tmp = ();
                        while ( $bmask >= CHUNK ) {
                            push @tmp, CHUNKMASK;
                            $bmask -= CHUNK;
                        }

                        # Push the final segment if there's a remainder
                        if ($bmask) {
                            push @tmp,
                                CHUNKMASK - ( ( 2**( CHUNK - $bmask ) ) - 1 );
                        }

                        # Add zero'd chunks to fill it out
                        while ( @tmp < IPV6CHUNKS ) {
                            push @tmp, 0x0;
                        }

                        # Finally, save the chunks
                        $bmask = [@tmp];

                    } else {
                        $bmask = undef;
                    }

                    if ( defined $bmask ) {

                        # Apply the mask to the base address
                        foreach ( 0 .. ( IPV6CHUNKS - 1 ) ) {
                            $$bnet[$_] &= $$bmask[$_];
                        }

                        # Calculate and save our broadcast address
                        @tmp = ();
                        foreach ( 0 .. ( IPV6CHUNKS - 1 ) ) {
                            $tmp[$_] =
                                $$bnet[$_] | ( $$bmask[$_] ^ CHUNKMASK );
                        }
                        push @rv, [@tmp];

                        # Save our mask
                        push @rv, $bmask;

                    } else {
                        pdebug( 'invalid netmask passed', PDLEVEL1 );
                    }
                }

            } else {
                pdebug( 'failed to convert IPv6 address', PDLEVEL1 );
            }
        } else {
            pdebug( 'failed to extract an IPv6 address', PDLEVEL1 );
        }

    } else {
        pdebug( 'IPv6 support not present', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, @rv );

    return @rv;
}

sub ipv6NetPacked {

    # Purpose:  Wrapper script for ipv6NetConvert that repacks all of its
    #           32bit chunks into opaque strings in network-byte order.
    # Returns:  Array
    # Usage:    @network = ipv6NetPacked($netAddr);

    my $netAddr = shift;
    my @rv;

    pdebug( 'entering w/%s', PDLEVEL1, $netAddr );
    pIn();

    @rv = ipv6NetConvert($netAddr);
    foreach (@rv) {
        $_ = pack 'NNNN', @$_;
    }

    pOut();
    pdebug( 'leaving w/%s', PDLEVEL1, @rv );

    return @rv;
}

sub _cmpArrays {

    # Purpose:  Compares IPv6 chunked address arrays
    # Returns:  -1:  net1 < net 2
    #            0:  net1 == net2
    #            1:  net1 > net2
    # Usage:    $rv = _cmpArrays( $aref1, $aref2 );

    my $aref1 = shift;
    my $aref2 = shift;
    my $rv    = 0;

    pdebug( 'entering w/%s, %s', PDLEVEL2, $aref1, $aref2 );
    pIn();

    while ( scalar @$aref1 ) {
        unless ( $$aref1[0] == $$aref2[0] ) {
            $rv = $$aref1[0] > $$aref2[0] ? 1 : -1;
            last;
        }
        shift @$aref1;
        shift @$aref2;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub ipv6NetIntersect {

    # Purpose:  Tests whether network address ranges intersect
    # Returns:  Integer, denoting whether an intersection exists, and what
    #           kind:
    #
    #              -1: destination range encompasses target range
    #               0: both ranges do not intersect at all
    #               1: target range encompasses destination range
    #
    # Usage:    $rv = ipv6NetIntersect($net1, $net2);

    my $tgt  = shift;
    my $dest = shift;
    my $rv   = 0;
    my ( @tnet, @dnet );

    pdebug( 'entering w/%s, %s', PDLEVEL1, $tgt, $dest );
    pIn();

    # Bypas if one or both isn't defined -- obviously no intersection
    unless ( !defined $tgt or !defined $dest ) {

        # Treat any array references as IPv6 addresses already translated into
        # 32bit integer chunks
        @tnet = ref($tgt)  eq 'ARRAY' ? $tgt  : ipv6NetConvert($tgt);
        @dnet = ref($dest) eq 'ARRAY' ? $dest : ipv6NetConvert($dest);

        # insert bogus numbers for non IP-address info
        @tnet = ( [ -1, 0, 0, 0 ] ) unless scalar @tnet;
        @dnet = ( [ -2, 0, 0, 0 ] ) unless scalar @dnet;

        # Dummy up broadcast address for those single IPs passed (in lieu of
        # network ranges)
        if ( $#tnet == 0 ) {
            $tnet[IPV6BRDCST] = $tnet[IPV6BASE];
            $tnet[IPV6MASK] = [ CHUNKMASK, CHUNKMASK, CHUNKMASK, CHUNKMASK ];
        }
        if ( $#dnet == 0 ) {
            $dnet[IPV6BRDCST] = $dnet[IPV6BASE];
            $dnet[IPV6MASK] = [ CHUNKMASK, CHUNKMASK, CHUNKMASK, CHUNKMASK ];
        }

        if (    _cmpArrays( $tnet[IPV6BASE], $dnet[IPV6BASE] ) <= 0
            and _cmpArrays( $tnet[IPV6BRDCST], $dnet[IPV6BRDCST] ) >= 0 ) {

            # Target fully encapsulates dest
            $rv = 1;

        } elsif ( _cmpArrays( $tnet[IPV6BASE], $dnet[IPV6BASE] ) >= 0
            and _cmpArrays( $tnet[IPV6BRDCST], $dnet[IPV6BRDCST] ) <= 0 ) {

            # Dest fully encapsulates target
            $rv = -1;

        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

{

    no strict 'refs';

    sub ipv6NumSort {

        # Purpose:  Sorts IPv6 addresses represented in numeric form
        # Returns:  -1, 0, 1
        # Usage:    @sorted = sort &ipv6NumSort @ipv4;

        my ($pkg) = caller;
        my ( $i, $rv );

        foreach $i ( 0 .. 3 ) {
            $rv = $${"${pkg}::a"}[$i] <=> $${"${pkg}::b"}[$i];
            last if $rv;
        }

        return $rv;
    }

    sub ipv6PackedSort {

        # Purpose:  Sorts IPv6 addresses represented by packed strings
        # Returns:  -1, 0, 1
        # Usage:    @sorted = sort &ipv6PackedSort @ipv6;

        no warnings 'once';

        my ($pkg) = caller;
        $a = [ unpack 'NNNN', ${"${pkg}::a"} ];
        $b = [ unpack 'NNNN', ${"${pkg}::b"} ];

        return ipv6NumSort();
    }

    sub ipv6StrSort {

        # Purpose:  Sorts IPv6 addresses represented in string form
        # Returns:  -1, 0, 1
        # Usage:    @sorted = sort &ipv4StrSort @ipv4;

        my ($pkg) = caller;
        my $a1    = ${"${pkg}::a"};
        my $b1    = ${"${pkg}::b"};
        my ( $i, $rv );

        $a1 =~ s#/.+##s;
        $a1 = [ unpack 'NNNN', inet_pton( AF_INET6(), $a1 ) ];
        $b1 =~ s#/.+##s;
        $b1 = [ unpack 'NNNN', inet_pton( AF_INET6(), $b1 ) ];

        foreach $i ( 0 .. 3 ) {
            $rv = $$a1[$i] <=> $$b1[$i];
            last if $rv;
        }

        return $rv;
    }
}

1;

__END__

=head1 NAME

Paranoid::Network::IPv6 - IPv6-related functions

=head1 VERSION

$Id: lib/Paranoid/Network/IPv6.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    use Paranoid::Network::IPv6;

    @net = ipv6NetConvert($netAddr);
    $rv = ipv6NetIntersect($net1, $net2);

or 

    use Paranoid::Network::IPv6 qw(:all);

    print "Valid IP address\n" if $netAddr =~ /^@{[ IPV6REGEX ]}$/;

    @net = ipv6NetConvert($netAddr);
    $broadcast = $net[IPV6BRDCST];

    use Paranoid::Network::IPv6 qw(:ipv6Sort);

    @nets = sort ipv6StrSort    @nets;
    @nets = sort ipv6PackedSort @nets;
    @nets = sort ipv6NumSort    @nets;

=head1 DESCRIPTION

This module contains a few convenience functions for working with IPv6
addresses.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    ipv6NetConvert ipv6NetPacked ipv6NetIntersect

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    base        @defaults
    constants   MAXIPV6CIDR IPV6REGEX IPV6CIDRRGX IPV6BASE 
                IPV6BRDCST IPV6MASK
    ipv6Sort    ipv6StrSort ipv6PackedSort ipv6NumSort
    all         @base @constants @ipv6Sort

=head1 SUBROUTINES/METHODS

=head2 ipv6NetConvert

    @net = ipv6NetConvert($netAddr);

This function takes an IPv4 network address in string format and converts it 
into and array of arrays.  The arrays will contain the base network address, 
the broadcast address, and the netmask, each split into native 32bit integer 
format chunks.  Each sub array is essentially what you would get from:

    @chunks = unpack 'NNNN', inet_pton(AF_INET6, '::1');

using '::1' as the sample IPv6 address.

The network address must have the netmask in CIDR format.  In the case of a 
single IP address, the array with only have one subarray, that of the IP 
itself, split into 32bit integers.

Passing any argument to this function that is not a string representation of
an IP address (including undef values) will cause this function to return an
empty array.

=head2 ipv6NetPacked

    @net = ipv6NetPacked('fe80::/64');

This function is a wrapper for B<ipv6NetConvert>, but instead of subarrays
each element is the packed (opaque) string as returned by B<inet_pton>.

=head2 ipv6NetIntersect

    $rv = ipv6NetIntersect($net1, $net2);

This function tests whether an IP or subnet intersects with another IP or
subnet.  The return value is essentially boolean, but the true value can vary
to indicate which is a subset of the other:

    -1: destination range encompasses target range
     0: both ranges do not intersect at all
     1: target range encompasses destination range

The function handles the same string formats as B<ipv6NetConvert>, but will
allow you to test single IPs in integer format as well.

=head2 ipv6StrSort

    @sorted = sort ipv6StrSort @nets;

This function allows IPv6 addresses and networks to be passed in string
format.  Networks can be in CIDR format.  Sorts in ascending order.
:w

=head2 ipv6PackedSort

    @sorted = sort ipv6PackedSort @nets;

This function sorts addresses that are in packed format, such as returned by
L<inet_pton>.  Sorts in ascending order. 

=head2 ipv6NumSort

    @sorted = sort ipv6NumSort @nets;

This function sorts addresses that are in unpacked, native integer format, such
as one gets from:

    @ip = unpack 'NNNN', inet_pton(AF_INET6, $ipAddr);

Sorts in ascending order.  List of addresses should be a list of lists.

=head1 CONSTANTS

These are only imported if explicitly requested or with the B<:all> tag.

=head2 MAXIPV6CIDR

Simply put: 128.  This is the largest CIDR notation supported in IPv6.

=head2 IPV6REGEX

Regular expression.

You can use this for validating IP addresses as such:

    $ip =~ m#^@{[ IPV6REGEX ]}$#;

or to extract potential IPs from  extraneous text:

    @ips = ( $string =~ m#(@{[ IPV6REGEX ]})#g);

=head2 IPV6CIDRRGX

Regular expression.

By default this will extract CIDR notation network addresses:

    @networks = ( $string =~ m#(@{[ IPV6CIDRRGX ]})#si );

=head2 IPV6BASE

This is the ordinal index of the base network address as returned by
B<ipv6NetConvert>.

=head2 IPV6BRDCST

This is the ordinal index of the broadcast address as returned by 
B<ipv6NetConvert>.

=head2 IPV6MASK

This is the ordinal index of the network mask as returned by 
B<ipv6NetConvert>.

=head1 DEPENDENCIES

=over

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Network::Socket>

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is free software.  Similar to Perl, you can redistribute it
and/or modify it under the terms of either:

  a)     the GNU General Public License
         <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
         Free Software Foundation <http://www.fsf.org/>; either version 1
         <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
         <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
  b)     the Artistic License 2.0
         <https://opensource.org/licenses/Artistic-2.0>,

subject to the following additional term:  No trademark rights to
"Paranoid" have been or are conveyed under any of the above licenses.
However, "Paranoid" may be used fairly to describe this unmodified
software, in good faith, but not as a trademark.

(c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)

