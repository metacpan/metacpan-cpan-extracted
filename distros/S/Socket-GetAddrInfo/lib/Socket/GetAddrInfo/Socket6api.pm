#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Socket::GetAddrInfo::Socket6api;

use strict;
use warnings;

use Carp;

our $VERSION = '0.22';

use Exporter 'import';
our @EXPORT_OK = qw(
   getaddrinfo
   getnameinfo
);

use Socket::GetAddrInfo ();

# Re-export all the AI_*, EAI_* and NI_* constants
my @constants = @{ $Socket::GetAddrInfo::EXPORT_TAGS{constants} };
push @EXPORT_OK, @constants;
Socket::GetAddrInfo->import( @constants );

=head1 NAME

C<Socket::GetAddrInfo::Socket6api> - Provide L<Socket::GetAddrInfo> functions
using L<Socket6> API

=head1 SYNOPSIS

 use Socket qw( AF_UNSPEC SOCK_STREAM );
 use Socket::GetAddrInfo::Socket6api qw( getaddrinfo getnameinfo );

 my $sock;

 my @res = getaddrinfo( "www.google.com", "www", AF_UNSPEC, SOCK_STREAM );

 die "Cannot resolve name - $res[0]" if @res == 1;

 while( @res >= 5 ) {
    my ( $family, $socktype, $protocol, $addr, undef ) = splice @res, 0, 5, ();

    $sock = IO::Socket->new();
    $sock->socket( $family, $socktype, $protocol ) or
      undef $sock, next;

    $sock->connect( $addr ) or undef $sock, next;

    last;
 }

 if( $sock ) {
    my ( $host, $service ) = getnameinfo( $sock->peername );
    print "Connected to $host:$service\n" if defined $host;
 }

=head1 DESCRIPTION

L<Socket::GetAddrInfo> provides the functions of C<getaddrinfo> and
C<getnameinfo> using a convenient interface where hints and address structures
are represented as hashes. L<Socket6> also provides these functions, in a form
taking and returning flat lists of values.

This module wraps the functions provided by C<Socket::GetAddrInfo> to provide
them in an identical API to C<Socket6>. It is intended to stand as a utility
for existing code written for the C<Socket6> API to use these functions
instead.

=cut

=head1 FUNCTIONS

=cut

=head2 @res = getaddrinfo( $host, $service, $family, $socktype, $protocol, $flags )

This version of the API takes the hints values as separate ordered parameters.
Unspecified parameters should be passed as C<0>.

If successful, this function returns a flat list of values, five for each
returned address structure. Each group of five elements will contain, in
order, the C<family>, C<socktype>, C<protocol>, C<addr> and C<canonname>
values of the address structure.

If unsuccessful, it will return a single value, containing the string error
message. To remain compatible with the C<Socket6> interface, this value does
not have the error integer part.

=cut

sub getaddrinfo
{
   @_ >= 2 and @_ <= 6 or 
      croak "Usage: getaddrinfo(host, service, family=0, socktype=0, protocol=0, flags=0)";

   my ( $host, $service, $family, $socktype, $protocol, $flags ) = @_;

   my ( $err, @res ) = Socket::GetAddrInfo::getaddrinfo( $host, $service, {
      flags    => $flags    || 0,
      family   => $family   || 0,
      socktype => $socktype || 0,
      protocol => $protocol || 0,
   } );

   return "$err" if $err;
   return map { $_->{family}, $_->{socktype}, $_->{protocol}, $_->{addr}, $_->{canonname} } @res;
}

=head2 ( $host, $service ) = getnameinfo( $addr, $flags )

This version of the API returns only the host name and service name, if
successfully resolved. On error, it will return an empty list. To remain
compatible with the C<Socket6> interface, no error information will be
supplied.

=cut

sub getnameinfo
{
   @_ >= 1 and @_ <= 2 or
      croak "Usage: getnameinfo(addr, flags=0)";

   my ( $addr, $flags ) = @_;

   my ( $err, $host, $service ) = Socket::GetAddrInfo::getnameinfo( $addr, $flags );

   return () if $err;
   return ( $host, $service );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
