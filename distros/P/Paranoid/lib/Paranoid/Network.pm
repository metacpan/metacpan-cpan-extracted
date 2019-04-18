# Paranoid::Network -- Network functions for paranoid programs
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Network.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Network;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Network::Socket;
use Paranoid::Network::IPv4 qw(:all);
use Paranoid::Network::IPv6 qw(:all);

($VERSION) = ( q$Revision: 2.07 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(ipInNetworks hostInDomains extractIPs netIntersect);
@EXPORT_OK   = ( @EXPORT, qw(NETMATCH HOSTNAME_REGEX) );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant HOSTNAME_REGEX =>
    qr#(?:[a-z0-9][a-z0-9\-]*)(?:\.[a-z0-9][a-z0-9\-]*)*\.?#s;

#####################################################################
#
# Module code follows
#
#####################################################################

{

    my $lmatch;

    sub NETMATCH : lvalue {
        $lmatch;
    }

}

sub ipInNetworks {

    # Purpose:  Checks to see if the IP occurs in the passed list of IPs and
    #           networks
    # Returns:  True (1) if the IP occurs, False (0) otherwise
    # Usage:    $rv = ipInNetworks($ip, @networks);

    my $ip       = shift;
    my @networks = grep {defined} @_;
    my $rv       = 0;
    my ( $family, @tmp );

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $ip, @networks );
    pIn();

    NETMATCH = undef;

    # Validate arguments
    if ( defined $ip ) {

        # Extract IPv4 address from IPv6 encoding
        $ip =~ s/^::ffff:(@{[ IPV4REGEX ]})$/$1/sio;

        # Check for IPv6 support
        if ( has_ipv6() or $] >= 5.012 ) {

            pdebug( 'Found IPv4/IPv6 support', PDLEVEL2 );
            $family =
                  $ip =~ m/^@{[ IPV4REGEX ]}$/so ? AF_INET()
                : $ip =~ m/^@{[ IPV6REGEX ]}$/so ? AF_INET6()
                :                                  undef;

        } else {

            pdebug( 'Found only IPv4 support', PDLEVEL2 );
            $family = AF_INET()
                if $ip =~ m/^@{[ IPV4REGEX ]}$/so;
        }
    }

    if ( defined $ip and defined $family ) {

        # Filter out non-family data from @networks
        @networks = grep {
            $family == AF_INET()
                ? m#^(?:@{[ IPV4CIDRRGX ]}|@{[ IPV4REGEX ]})$#so
                : m#^(?:@{[ IPV6CIDRRGX ]}|@{[ IPV6REGEX ]})$#so
        } @networks;

        pdebug( 'networks to compare: %s', PDLEVEL2, @networks );

        # Start comparisons
        foreach (@networks) {
            if ($family == AF_INET()
                ? ipv4NetIntersect( $ip, $_ )
                : ipv6NetIntersect( $ip, $_ )
                ) {
                NETMATCH = $_;
                $rv = 1;
                last;
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub hostInDomains {

    # Purpose:  Checks to see if the host occurs in the list of domains
    # Returns:  True (1) if the host occurs, False (0) otherwise
    # Usage:    $rv = hostInDomains($hostname, @domains);

    my $host    = shift;
    my @domains = @_;
    my $rv      = 0;
    my $domain;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $host, @domains );
    pIn();

    NETMATCH = undef;

    if ( defined $host and $host =~ /^@{[ HOSTNAME_REGEX ]}$/so ) {

        # Filter out non-domains
        @domains =
            grep { defined $_ && m/^@{[ HOSTNAME_REGEX ]}$/so } @domains;

        # Start the comparison
        if (@domains) {
            foreach $domain (@domains) {
                if ( $host =~ /^(?:[\w\-]+\.)*\Q$domain\E$/si ) {
                    NETMATCH = $domain;
                    $rv = 1;
                    last;
                }
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub extractIPs {

    # Purpose:  Extracts IPv4/IPv6 addresses from arbitrary text.
    # Returns:  List containing extracted IP addresses
    # Usage:    @ips = extractIPs($string1, $string2);

    my @strings = @_;
    my ( $string, @ips, $ip, @tmp, @rv );

    pdebug( 'entering w/%d strings', PDLEVEL1, scalar @strings );
    pIn();

    foreach $string (@strings) {
        next unless defined $string;

        # Look for IPv4 addresses
        @ips = ( $string =~ /(@{[ IPV4CIDRRGX ]}|@{[ IPV4REGEX ]})/sog );

        # Validate them by filtering through inet_aton
        foreach $ip (@ips) {
            @tmp = split m#/#s, $ip;
            push @rv, $ip if defined inet_aton( $tmp[0] );
        }

        # If Socket6 is present or we have Perl 5.14 or higher we'll check
        # for IPv6 addresses
        if ( has_ipv6() or $] >= 5.012 ) {

            @ips = ( $string =~
                    m/(@{[ IPV6CIDRRGX ]}|@{[ IPV6REGEX ]})/sogix );

            # Filter out addresses with more than one ::
            @ips = grep { scalar(m/(::)/sg) <= 1 } @ips;

            # Validate remaining addresses with inet_pton
            foreach $ip (@ips) {
                @tmp = split m#/#s, $ip;
                push @rv, $ip
                    if defined inet_pton( AF_INET6(), $tmp[0] );
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, @rv );

    return @rv;
}

sub netIntersect {

    # Purpose:  Tests whether network address ranges intersect
    # Returns:  Integer, denoting whether an intersection exists, and what
    #           kind:
    #
    #               -1: destination range encompasses target range
    #                0: both ranges do not intersect at all
    #                1: target range encompasses destination range
    #
    # Usage:    $rv = netIntersect( $cidr1, $cidr2 );

    my $target = shift;
    my $dest   = shift;
    my $rv     = 0;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $target, $dest );
    pIn();

    if ( defined $target and defined $dest ) {
        if ( $target =~ m/^(?:@{[ IPV4CIDRRGX ]}|@{[ IPV4REGEX ]})$/s ) {
            $rv = ipv4NetIntersect( $target, $dest );
        } elsif ( $target =~ m/^(?:@{[ IPV6CIDRRGX ]}|@{[ IPV6REGEX ]})$/si )
        {
            $rv = ipv6NetIntersect( $target, $dest )
                if has_ipv6()
                    or $] >= 5.012;
        } else {
            pdebug(
                'target string (%s) doesn\'t seem to match '
                    . 'an IP/network address',
                PDLEVEL1, $target
                );
        }
    } else {
        pdebug( 'one or both arguments are not defined', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Network - Network functions for paranoid programs

=head1 VERSION

$Id: lib/Paranoid/Network.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Network;

  $rv  = ipInNetworks($ip, @networks);
  $rv  = hostInDomains($host, @domains);
  $cidr = Paranoid::Network::NETMATCH();
  @ips = extractIPs($string1);
  @ips = extractIPs(@lines);
  $rv  = netIntersect( $cidr1, $cidr2 );

=head1 DESCRIPTION

This modules contains functions that may be useful for working with network
data.  It attempts to be IPv4/IPv6 agnostic, assuming IPv6 support is present.
Due to the gradual introduction of IPv6 support into Perl there may be
caveats.  Please consult L<Paranoid::Network::Socket> for more details.

I<NETMATCH> and I<HOSTNAME_REGEX> are not exported by default.

=head1 SUBROUTINES/METHODS

=head2 ipInNetworks

  $rv = ipInNetworks($ip, @networks);

This function checks the passed IP (in string format) against each of the 
networks or IPs in the list and returns true if there's a match.  The list of 
networks can be either individual IP address or network addresses in CIDR 
notation or with full netmasks:

  @networks = qw(127.0.0.1 
                 192.168.0.0/24 
                 172.16.12.0/255.255.240.0);

You can safely comingle IPv4 & IPv6 addresses in the list to check against.
Addresses not belonging to the same address family as the IP being tested will
be ignored.

B<NOTE:>  IPv4 addresses encoded as IPv6 addresses, e.g.:

  ::ffff:192.168.0.5

are supported, however an IP address submitted in this format as the IP to
test for will be converted to a pure IPv4 address and compared only against
the IPv4 networks.  This is meant as a convenience to the developer supporting
dual-stack systems to avoid having to list IPv4 networks in the array twice
like so:

  ::ffff:192.168.0.0/120, 192.168.0.0/24

Just list IPv4 as IPv4, IPv6 as IPv6, and this routine will convert
IPv6-encoded IPv4 addresses automatically.  This would make the following test
return a true value:

  ipInNetworks( '::ffff:192.168.0.5', '192.168.0.0/24' );

but

  ipInNetworks( '::ffff:192.168.0.5', '::ffff:192.168.0.0/120' );

return a false value.  This may seem counter intuitive, but it simplifies
things in (my alternate) reality.

Please note that this automatic conversion only applies to the B<IP> argument,
not to any member of the network array.

=head2 hostInDomains

  $rv = hostInDomains($host, @domains);

This function checks the passed hostname (fully qualified) against each 
of the domains in the list and returns true if there's a match.  None of the
domains should have the preceding '.' (i.e., 'foo.com' rather than 
'.foo.com').

=head2 NETMATCH

  $cidr = Paranoid::Network::NETMATCH();

This stores the IP, network address, or domain that matched in 
I<ipInNetworks> or I<hostInDomains>.  This returns B<undef> if any
function call fails to make a match.

=head2 HOSTNAME_REGEX

    $rv = $hostname =~ /^@{[ HOSTNAME_REGEX ]}$/so;

This constant is just a regex meant to be a basic sanity check for appropriate
hostnames.  It is probably overly strict in accordance with outdated RFCs.

=head2 extractIPs

    @ips = extractIPs($string1);
    @ips = extractIPs(@lines);

This function extracts IPv4/IPv6 addresses from arbitrary text.  IPv6 support
is contingent upon the presence of proper support (please see
L<Paranoid::Network::Socket> for more details).

This extracts only IP addresses, not network addresses in CIDR or dotted octet
notation.  In the case of the latter the netmask will be extracted as an
additional address.

B<NOTE:> in the interest of performance this function does only rough regex
extraction of IP-looking candidates, then runs them through B<inet_aton> (for
IPv4) and B<inet_pton> (for IPv6) to see if they successfully convert.  Even
with the overhead of B<Paranoid> (with debugging and I<loadModule> calls for
Socket6 and what-not) it seems that this is an order of a magnitude faster
than doing a pure regex extraction & validation of IPv6 addresses.

B<NOTE:> Like the B<ipInNetworks> function we filter out IPv4 addresses encoded
as IPv6 addresses since that address is already returned as a pure IPv4
address.

=head2 netIntersect

  $rv = netIntersect( $cidr1, $cidr2 );

This function is an IPv4/IPv6 agnostic wrapper for the B<ipv{4,6}NetIntersect>
functions provided by L<Paranoid::Network::IPv{4,6}> modules.  The return
value from which ever function called is passed on directly.  Passing this
function non-IP or undefined values simply returns a zero.

=head1 DEPENDENCIES

=over

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Network::Socket>

=item o

L<Paranoid::Network::IPv4>

=item o

L<Paranoid::Network::IPv6>

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

