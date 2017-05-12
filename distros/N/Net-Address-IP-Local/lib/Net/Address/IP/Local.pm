#
# Net::Address::IP::Local class,
# a class for discovering the local system's IP address.
#
# (C) 2005-2009 Julian Mehnle <julian@mehnle.net>
# $Id: Local.pm 24 2009-01-14 21:23:40Z julian $
#
###############################################################################

=head1 NAME

Net::Address::IP::Local - A class for discovering the local system's IP address

=cut

package Net::Address::IP::Local;

=head1 VERSION

0.1.2

=cut

use version; our $VERSION = qv('0.1.2');

use warnings;
use strict;

use Error ':try';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant remote_address_ipv4_default => '198.41.0.4';           # a.root-servers.net
use constant remote_address_ipv6_default => '2001:503:ba3e::2:30';  # a.root-servers.net

use constant remote_port_default         => 53;                     # DNS

=head1 SYNOPSIS

    use Net::Address::IP::Local;
    
    # Get the local system's IP address that is "en route" to "the internet":
    my $address      = Net::Address::IP::Local->public;
    my $address_ipv4 = Net::Address::IP::Local->public_ipv4;
    my $address_ipv6 = Net::Address::IP::Local->public_ipv6;
    
    # Get the local system's IP address that is "en route" to the given remote
    # IP address:
    my $address = Net::Address::IP::Local->connected_to($remote_address);

=head1 DESCRIPTION

B<Net::Address::IP::Local> discovers the local system's IP address that would
be used as the source address when contacting "the internet" or a certain
specified remote IP address.

=cut

# Implementation:
###############################################################################

=head2 Class methods

This class just provides the following class methods:

=over

=item B<public>: returns I<string>; throws I<Net::Address::IP::Local::Error>

Returns the textual representation of the local system's IP address that is
"en route" to "the internet".  If the system supports IPv6 and has an IPv6
address that is "en route" to "the internet", that is returned.  Otherwise, the
IPv4 address that is "en route" to "the internet" is returned.  If there is no
route at all to the internet, a I<Net::Address::IP::Local::Error> exception is
thrown.

=cut

sub public {
    my ($class) = @_;
    
    return $class->connected_to($class->remote_address_ipv4_default)
        if not $class->ipv6_support;
        # Short-cut for the common case with no IPv6 support.
    
    my $ip_address;
    
    try {
        $ip_address = $class->connected_to($class->remote_address_ipv6_default);
    }
    catch Net::Address::IP::Local::Error with {
        my $error = shift;
        try {
            $ip_address = $class->connected_to($class->remote_address_ipv4_default);
        }
        catch Net::Address::IP::Local::Error with {
            # If neither the IPv4 nor IPv6 local address could be determined,
            # re-throw the first error that occurred:
            $error->throw;
        };
    };
    
    return $ip_address;
}

=item B<public_ipv4>: returns I<string>; throws I<Net::Address::IP::Local::Error>

Returns the textual representation of the local system's IPv4 address that is "en
route" to "the internet".  If there is no IPv4 route to the internet, a
I<Net::Address::IP::Local::Error> exception is thrown.

=cut

sub public_ipv4 {
    my ($class) = @_;
    $class->ipv4_support
        or throw Net::Address::IP::Local::Error("IPv4 not supported");
    return $class->connected_to($class->remote_address_ipv4_default);
}

=item B<public_ipv6>: returns I<string>; throws I<Net::Address::IP::Local::Error>

Returns the textual representation of the local system's IPv6 address that is "en
route" to "the internet".  If there is no IPv6 route to the internet, a
I<Net::Address::IP::Local::Error> exception is thrown.

=cut

sub public_ipv6 {
    my ($class) = @_;
    $class->ipv6_support
        or throw Net::Address::IP::Local::Error("IPv6 not supported");
    return $class->connected_to($class->remote_address_ipv6_default);
}

=item B<connected_to($remote_address)>: returns I<string>; throws
I<Net::Address::IP::Local::Error>

Returns the textual representation of the local system's IP address that is "en
route" to the given remote IP address.  If there is no route to the given
remote IP address, a I<Net::Address::IP::Local::Error> exception is thrown.

=cut

sub connected_to {
    my ($class, $remote_address) = @_;
    
    my $socket_class;
    if ($class->ipv6_support) {
        $socket_class = 'IO::Socket::INET6';
    }
    elsif ($class->ipv4_support) {
        $socket_class = 'IO::Socket::INET';
    }
    else {
        throw Net::Address::IP::Local::Error("Neither IPv4 nor IPv6 supported");
    }
    
    my $socket = $socket_class->new(
        Proto       => 'udp',
        PeerAddr    => $remote_address,
        PeerPort    => $class->remote_port_default
    );
    
    defined($socket)
        or throw Net::Address::IP::Local::Error("Unable to create UDP socket: $!");
    
    return $socket->sockhost;
}

=back

=cut

# Private helper methods:

my $ipv4_support;

sub ipv4_support {
    if (not defined($ipv4_support)) {
        eval { require IO::Socket::INET };
        $ipv4_support = not $@;
    }
    return $ipv4_support;
}

my $ipv6_support;

sub ipv6_support {
    if (not defined($ipv6_support)) {
        eval { require IO::Socket::INET6 };
        $ipv6_support = not $@;
    }
    return $ipv6_support;
}

=head1 AVAILABILITY and SUPPORT

The latest version of Net::Address::IP::Local is available on CPAN and at
L<http://www.mehnle.net/software/net-address-ip-local-perl>.

Support is usually (but not guaranteed to be) given by the author, Julian
Mehnle <julian@mehnle.net>.

=head1 AUTHOR and LICENSE

Net::Address::IP::Local is Copyright (C) 2005-2009 Julian Mehnle
<julian@mehnle.net>.

Net::Address::IP::Local is free software.  You may use, modify, and distribute
it under the same terms as Perl itself, i.e. under the GNU GPL or the Artistic
License.

=cut

package Net::Address::IP::Local::Error;
use base qw(Error::Simple);

package Net::Address::IP::Local;

TRUE;
