#
# Net::Address::IPv4::Local class,
# a class for discovering the local system's IP address.
#
# (C) 2005 Julian Mehnle <julian@mehnle.net>
# $Id: Local.pm,v 1.4 2005/05/05 12:57:28 julian Exp $
#
##############################################################################

=head1 NAME

Net::Address::IPv4::Local - A class for discovering the local system's IP
address

=cut

package Net::Address::IPv4::Local;

=head1 VERSION

0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

    use Net::Address::IPv4::Local;
    
    # Get the local system's IP address that is "connected" to "the internet":
    my $address = Net::Address::IPv4::Local->public;
    
    # Get the local system's IP address that is "connected" to the given remote
    # IP address:
    my $address = Net::Address::IPv4::Local->connected_to($remote_address);

=cut

use warnings;
use strict;

use Error qw(:try);

use IO::Socket::INET;

use constant DEFAULT_REMOTE_ADDRESS => '198.41.0.4';    # a.root-servers.net
use constant DEFAULT_REMOTE_PORT    => 53;              # DNS

# Interface:
##############################################################################

=head1 DESCRIPTION

B<Net::Address::IPv4::Local> discovers the local system's IP address that would
be used as the source address when contacting "the internet" or a certain
specified remote IP address.

=cut

sub public;
sub connected_to;

# Implementation:
##############################################################################

=head2 Instance methods

This class just provides the following instance methods:

=over

=item B<public>: RETURNS SCALAR; THROWS Net::Address::IPv4::Local::Error

Returns the textual representation of the local system's IP address that is
"connected" to "the internet".

=cut

sub public {
    my ($class) = @_;
    return $class->connected_to(DEFAULT_REMOTE_ADDRESS);
}

=item B<connected_to($remote_address)>: RETURNS SCALAR; THROWS
Net::Address::IPv4::Local::Error

Returns the textual representation of the local system's IP address that is
"connected" to the given remote IP address.

=cut

sub connected_to {
    my ($class, $remote_address) = @_;
    
    my $socket = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => $remote_address,
        PeerPort    => DEFAULT_REMOTE_PORT
    );
    
    throw Net::Address::IPv4::Local::Error("Unable to create UDP socket: $!")
        if not defined($socket);
    
    return inet_ntoa($socket->sockaddr);
}

=back

=head1 AVAILABILITY and SUPPORT

The latest version of Net::Address::IPv4::Local is available on CPAN and at
L<http://www.mehnle.net/software/net-address-ipv4-local>.

Support is usually (but not guaranteed to be) given by the author, Julian
Mehnle <julian@mehnle.net>.

=head1 AUTHOR and LICENSE

Net::Address::IPv4::Local is Copyright (C) 2005 Julian Mehnle
<julian@mehnle.net>.

Net::Address::IPv4::Local is free software.  You may use, modify, and
distribute it under the same terms as Perl itself, i.e. under the GNU GPL or
the Artistic License.

=cut

package Net::Address::IPv4::Local::Error;
use base qw(Error::Simple);

package Net::Address::IPv4::Local;

1;

# vim:tw=79
