#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Socket::GetAddrInfo::Strict;

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

C<Socket::GetAddrInfo::Strict> - Provide L<Socket::GetAddrInfo> functions
which throw exceptions

=head1 SYNOPSIS

 use Socket qw( SOCK_STREAM );
 use Socket::GetAddrInfo::Strict qw( getaddrinfo getnameinfo );
 use IO::Socket;

 my $sock;

 my %hints = ( socktype => SOCK_STREAM );
 my @res = getaddrinfo( "www.google.com", "www", \%hints );

 while( my $ai = shift @res ) {

    $sock = IO::Socket->new();
    $sock->socket( $ai->{family}, $ai->{socktype}, $ai->{protocol} ) or
       undef $sock, next;

    $sock->connect( $ai->{addr} ) or undef $sock, next;

    last;
 }

 if( $sock ) {
    my ( $host, $service ) = getnameinfo( $sock->peername );
    print "Connected to $host:$service\n";
 }

=head1 DESCRIPTION

L<Socket::GetAddrInfo> provides the functions of C<getaddrinfo> and
C<getnameinfo>, which return lists whose first element is error value, or
false indicating no error occured.

This module wraps the functions provided by C<Socket::GetAddrInfo> to check
this error value, and throw an exception (using C<die>) if an error occured.
If not, then the remaining values are returned as normal. This can simplify
the logic of a program which otherwise simply throws its own exception on
failure anyway.

=cut

=head1 FUNCTIONS

=cut

=head2 @res = getaddrinfo( $host, $service, $hints )

After a successful lookup, returns the list of address structures, as
documented in L<Socket::GetAddrInfo>. If the lookup fails, an exception
containing the string form of the error is thrown instead.

=cut

sub getaddrinfo
{
   my ( $err, @res ) = Socket::GetAddrInfo::getaddrinfo( @_ );
   die "$err\n" if $err;
   return @res;
}

=head2 ( $host, $service ) = getnameinfo( $addr, $flags, $xflags )

After a successful lookup, returns the host and service name, as
documented in L<Socket::GetAddrInfo>. If the lookup fails, an exception
containing the string form of the error is thrown instead.

=cut

sub getnameinfo
{
   my ( $err, $host, $service ) = Socket::GetAddrInfo::getnameinfo( @_ );
   die "$err\n" if $err;
   return ( $host, $service );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
