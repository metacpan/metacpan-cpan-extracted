# Paranoid::Network::IPv4 -- IPv4-specific network functions
#
# $Id: lib/Paranoid/Network/IPv4.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
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

package Paranoid::Network::IPv4;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Network::Socket;

my @base      = qw(ipv4NetConvert ipv4NetIntersect);
my @constants = qw(MAXIPV4CIDR IPV4REGEX IPV4CIDRRGX IPV4BASE IPV4BRDCST
    IPV4MASK);
my @ipv4sort = qw(ipv4NumSort ipv4StrSort ipv4PackedSort);

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );
@EXPORT      = @base;
@EXPORT_OK   = ( @base, @constants, @ipv4sort );
%EXPORT_TAGS = (
    all       => [@EXPORT_OK],
    base      => [@base],
    constants => [@constants],
    ipv4Sort  => [@ipv4sort],
    );

use constant MAXIPV4CIDR => 32;
use constant IPV4REGEX =>
    qr/(?:(?:25[0-5]|2[0-4][0-9]|1?\d\d?)\.){3}(?:25[0-5]|2[0-4][0-9]|1?\d\d?)/s;
use constant IPV4CIDRRGX =>
    qr#@{[ IPV4REGEX ]}/(?:(?:3[0-2]|[12]?\d)|@{[ IPV4REGEX ]})#s;
use constant FULLMASK   => 0xffffffff;
use constant IPV4BASE   => 0;
use constant IPV4BRDCST => 1;
use constant IPV4MASK   => 2;

#####################################################################
#
# Module code follows
#
#####################################################################

sub ipv4NetConvert {

    # Purpose:  Takes a string representation of an IPv4 network
    #           address and returns a list containing the binary
    #           network address, broadcast address, and netmask.
    #           Also allows for a plain IP being passed, in which
    #           case it only returns the binary IP.
    # Returns:  Array, empty on errors
    # Usage:    @network = ipv4NetConvert($netAddr);

    my $netAddr = shift;
    my ( $bnet, $bmask, $t, @rv );

    pdebug( 'entering w/%s', PDLEVEL1, $netAddr );
    pIn();

    # Extract net address, mask
    if ( defined $netAddr ) {
        ($t) = ( $netAddr =~ m#^(@{[ IPV4CIDRRGX ]}|@{[ IPV4REGEX ]})$#s )[0];
        ( $bnet, $bmask ) = split m#/#s, $t if defined $t;
    }

    if ( defined $bnet and length $bnet ) {

        # First, convert $bnet to see if we have a valid IP address
        $bnet = unpack 'N', inet_aton($bnet);

        if ( defined $bnet and length $bnet ) {

            # Save our network address
            push @rv, $bnet;

            if ( defined $bmask and length $bmask ) {

                # Convert netmask
                $bmask =
                      $bmask !~ /^\d+$/s ? unpack 'N', inet_aton($bmask)
                    : $bmask <= MAXIPV4CIDR
                    ? FULLMASK - ( ( 2**( MAXIPV4CIDR - $bmask ) ) - 1 )
                    : undef;

                if ( defined $bmask and length $bmask ) {

                    # Apply the mask to the base address
                    $rv[IPV4BASE] = $rv[IPV4BASE] & $bmask;

                    # Calculate and save our broadcast address
                    push @rv, $bnet | ( $bmask ^ FULLMASK );

                    # Save our mask
                    push @rv, $bmask;

                } else {
                    pdebug( 'invalid netmask passed', PDLEVEL1 );
                }
            }
        } else {
            pdebug( 'failed to convert IPv4 address', PDLEVEL1 );
        }
    } else {
        pdebug( 'failed to extract an IPv4 address', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, @rv );

    return @rv;
}

sub ipv4NetIntersect {

    # Purpose:  Tests whether network address ranges intersect
    # Returns:  Integer, denoting whether an intersection exists, and what
    #           kind:
    #
    #              -1: destination range encompasses target range
    #               0: both ranges do not intersect at all
    #               1: target range encompasses destination range
    #
    # Usage:    $rv = ipv4NetIntersect($net1, $net2);

    my $tgt  = shift;
    my $dest = shift;
    my $rv   = 0;
    my ( @tnet, @dnet );

    pdebug( 'entering w/%s, %s', PDLEVEL1, $tgt, $dest );
    pIn();

    # Bypas if one or both isn't defined -- obviously no intersection
    unless ( !defined $tgt or !defined $dest ) {

        # Convert addresses (also allows for raw IPs (32bit integers) to be
        # passed)
        @tnet = $tgt  =~ /^\d+$/s ? ($tgt)  : ipv4NetConvert($tgt);
        @dnet = $dest =~ /^\d+$/s ? ($dest) : ipv4NetConvert($dest);

        # insert bogus numbers for non IP-address info
        @tnet = (-1) unless scalar @tnet;
        @dnet = (-2) unless scalar @dnet;

        # Dummy up broadcast address for those single IPs passed (in lieu of
        # network ranges)
        $tnet[IPV4BRDCST] = $tnet[IPV4BASE] if $#tnet == 0;
        $dnet[IPV4BRDCST] = $dnet[IPV4BASE] if $#dnet == 0;

        if (    $tnet[IPV4BASE] <= $dnet[IPV4BASE]
            and $tnet[IPV4BRDCST] >= $dnet[IPV4BRDCST] ) {

            # Target fully encapsulates dest
            $rv = 1;

        } elsif ( $tnet[IPV4BASE] >= $dnet[IPV4BASE]
            and $tnet[IPV4BRDCST] <= $dnet[IPV4BRDCST] ) {

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

    sub ipv4NumSort {

        # Purpose:  Sorts IPv4 addresses represented in numeric form
        # Returns:  -1, 0, 1
        # Usage:    @sorted = sort &ipv4NumSort @ipv4;

        my ($pkg) = caller;

        return ${"${pkg}::a"} <=> ${"${pkg}::b"};
    }

    sub ipv4PackedSort {

        # Purpose:  Sorts IPv4 addresses represented in packed strings
        # Returns:  -1, 0, 1
        # Usage:    @sorted = sort &ipv4PackedSort @ipv4;

        my ($pkg) = caller;

        my $a1 = unpack 'N', ${"${pkg}::a"};
        my $b1 = unpack 'N', ${"${pkg}::b"};

        return $a1 <=> $b1;
    }

    sub ipv4StrSort {

        # Purpose:  Sorts IPv4 addresses represented in string form
        # Returns:  -1, 0, 1
        # Usage:    @sorted = sort &ipv4StrSort @ipv4;

        my ($pkg) = caller;

        my $a1 = ${"${pkg}::a"};
        my $b1 = ${"${pkg}::b"};

        $a1 =~ s#/.+##s;
        $a1 = unpack 'N', inet_aton($a1);
        $b1 =~ s#/.+##s;
        $b1 = unpack 'N', inet_aton($b1);

        return $a1 <=> $b1;
    }
}

1;

__END__

=head1 NAME

Paranoid::Network::IPv4 - IPv4-related functions

=head1 VERSION

$Id: lib/Paranoid/Network/IPv4.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    use Paranoid::Network::IPv4;

    @net = ipv4NetConvert($netAddr);
    $rv = ipv4NetIntersect($net1, $net2);

    use Paranoid::Network::IPv4 qw(:all);

    print "Valid IP address\n" if $netAddr =~ /^@{[ IPV4REGEX ]}$/;

    @net = ipv4NetConvert($netAddr);
    $broadcast = $net[IPV4BRDCST];

    use Paranoid::Network::IPv4 qw(:ipv4Sort);

    @nets = sort ipv4StrSort    @nets;
    @nets = sort ipv4PackedSort @nets;
    @nets = sort ipv4NumSort    @nets;

=head1 DESCRIPTION

This module contains a few convenience functions for working with IPv4
addresses.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    ipv4NetConvert ipv4NetIntersect

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    base        @defaults
    constants   MAXIPV4CIDR IPV4REGEX IPV4CIDRRGX IPV4BASE 
                IPV4BRDCST IPV4MASK
    ipv4Sort    ipv4NumSort ipv4StrSort ipv4PackedSort
    all         @base @constants @ipv4sort

=head1 SUBROUTINES/METHODS

=head2 ipv4NetConvert

    @net = ipv4NetConvert($netAddr);

This function takes an IPv4 network address in string format and converts it 
into an array containing the base network address, the broadcast address, and 
the netmask, in integer format.  The network address can have the netmask in
either CIDR format or dotted quads.

In the case of a single IP address, the array with only have one element, that
of the IP in integer format.

Passing any argument to this function that is not a string representation of
an IP address (including undef values) will cause this function to return an
empty array.

=head2 ipv4NetIntersect

    $rv = ipv4NetIntersect($net1, $net2);

This function tests whether an IP or subnet intersects with another IP or
subnet.  The return value is essentially boolean, but the true value can vary
to indicate which is a subset of the other:

    -1: destination range encompasses target range
     0: both ranges do not intersect at all
     1: target range encompasses destination range

The function handles the same string formats as B<ipv4NetConvert>, but will
allow you to test single IPs in integer format as well.

=head2 ipv4StrSort

    @sorted = sort ipv4StrSort @nets;

This function allows IPv4 addresses and networks to be passed in string
format.  Networks can be in CIDR format.  Sorts in ascending order.

=head2 ipv4PackedSort

    @sorted = sort ipv4PackedSort @nets;

This function sorts IPv4 addresses as returned by L<inet_aton>.  Sorts in
ascending order.

=head2 ipv4NumSort

    @sorted = sort ipv4NumSort @nets;

This function is rather pointless, but is included merely for completeness.
Addresses are in unpacked, native integer format, such as one gets from:

    $ip = unpack 'N', inet_aton($ipAddr);

Sorts in ascending order.

=head1 CONSTANTS

These are only imported if explicitly requested or with the B<:all> tag.

=head2 MAXIPV4CIDR

Simply put: 32.  This is the largest CIDR notation supported in IPv4.

=head2 IPV4REGEX

Regular expression.

You can use this for validating IP addresses as such:

    $ip =~ m#^@{[ IPV4REGEX ]}$#;

or to extract potential IPs from  extraneous text:

    @ips = ( $string =~ m#(@{[ IPV4REGEX ]})#gsm);

=head2 IPV4CIDRRGX

Regular expression.

By default this will test a CIDR notation or dotted quad network address:

    $netaddr =~ m#@{[ IPV4CIDRRGX ]}$#s;

or extract network addresses from a string:

    @networks = ( $string =~ m#(@{[ IPV4CIDRRGX ]})#s );

=head2 IPV4BASE

This is the ordinal index of the base network address as returned by
B<ipv4NetConvert>.

=head2 IPV4BRDCST

This is the ordinal index of the broadcast address as returned by 
B<ipv4NetConvert>.

=head2 IPV4MASK

This is the ordinal index of the network mask as returned by 
B<ipv4NetConvert>.

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

