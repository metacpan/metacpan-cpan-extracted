#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2012 -- leonerd@leonerd.org.uk

package Socket::GetAddrInfo;

use strict;
use warnings;

use Carp;

our $VERSION = '0.22';

require Exporter;
our @EXPORT_OK;
our %EXPORT_TAGS;

foreach my $impl (qw( Core XS Emul )) {
   my $class = "Socket::GetAddrInfo::$impl";
   my $file  = "Socket/GetAddrInfo/$impl.pm";
   eval {
      # Each of the impls puts its symbols directly in our package
      # Don't need to ->import
      require $file;
   };

   last if defined &getaddrinfo;
}

=head1 NAME

C<Socket::GetAddrInfo> - address-family independent name resolving functions

=head1 SYNOPSIS

 use Socket qw( SOCK_STREAM );
 use Socket::GetAddrInfo qw( getaddrinfo getnameinfo );
 use IO::Socket;

 my %hints = ( socktype => SOCK_STREAM );
 my ( $err, @res ) = getaddrinfo( "www.google.com", "www", \%hints );

 die "Cannot resolve name - $err" if $err;

 my $sock;

 foreach my $ai ( @res ) {
    my $candidate = IO::Socket->new();

    $candidate->socket( $ai->{family}, $ai->{socktype}, $ai->{protocol} )
       or next;

    $candidate->connect( $ai->{addr} )
       or next;

    $sock = $candidate;
    last;
 }

 if( $sock ) {
    my ( $err, $host, $service ) = getnameinfo( $sock->peername );
    print "Connected to $host:$service\n" if !$err;
 }

=head1 DESCRIPTION

The RFC 2553 functions C<getaddrinfo> and C<getnameinfo> provide an abstracted
way to convert between a pair of host name/service name and socket addresses,
or vice versa. C<getaddrinfo> converts names into a set of arguments to pass
to the C<socket()> and C<connect()> syscalls, and C<getnameinfo> converts a
socket address back into its host name/service name pair.

These functions provide a useful interface for performing either of these name
resolution operation, without having to deal with IPv4/IPv6 transparency, or
whether the underlying host can support IPv6 at all, or other such issues.
However, not all platforms can support the underlying calls at the C layer,
which means a dilema for authors wishing to write forward-compatible code.
Either to support these functions, and cause the code not to work on older
platforms, or stick to the older "legacy" resolvers such as
C<gethostbyname()>, which means the code becomes more portable.

This module attempts to solve this problem, by detecting at compiletime
whether the underlying OS will support these functions. If it does not, the
module will use pure-perl emulations of the functions using the legacy
resolver functions instead. The emulations support the same interface as the
real functions, and behave as close as is resonably possible to emulate using
the legacy resolvers. See L<Socket::GetAddrInfo::Emul> for details on the
limits of this emulation.

As of Perl version 5.14.0, Perl already supports C<getaddrinfo> in core. On
such a system, this module simply uses the functions provided by C<Socket>,
and does not need to use its own compiled XS, or pure-perl legacy emulation.

As C<Socket> in core now provides all the functions also provided by this
module, it is likely this may be the last released version of this module. And
code currently using this module would be advised to switch to using core
C<Socket> instead.

=cut

=head1 EXPORT TAGS

The following tags may be imported by C<use Socket::GetAddrInfo qw( :tag )>:

=over 8

=item AI

Imports all of the C<AI_*> constants for C<getaddrinfo> flags

=item NI

Imports all of the C<NI_*> constants for C<getnameinfo> flags

=item EAI

Imports all of the C<EAI_*> for error values

=item constants

Imports all of the above constants

=back

=cut

$EXPORT_TAGS{AI}  = [ grep m/^AI_/,       @EXPORT_OK ];
$EXPORT_TAGS{NI}  = [ grep m/^NI(?:x)?_/, @EXPORT_OK ];
$EXPORT_TAGS{EAI} = [ grep m/^EAI_/,      @EXPORT_OK ];

$EXPORT_TAGS{constants} = [ map @{$EXPORT_TAGS{$_}}, qw( AI NI EAI ) ];

sub import
{
   my $class = shift;
   my %symbols = map { $_ => 1 } @_;

   $symbols{':newapi'} and croak ":newapi tag is no longer supported by Socket::GetAddrInfo; just 'use' it directly";
   $symbols{':Socket6api'} and croak ":Socket6api tag is no longer supported by Socket::GetAddrInfo; use Socket::GetAddrInfo::Socket6api instead";

   local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
   Exporter::import( $class, keys %symbols );
}

=head1 FUNCTIONS

=cut

=head2 ( $err, @res ) = getaddrinfo( $host, $service, $hints )

C<getaddrinfo> turns human-readable text strings (containing hostnames,
numeric addresses, service names, or port numbers) into sets of binary values
containing socket-level representations of these addresses.

When given both host and service, this function attempts to resolve the host
name to a set of network addresses, and the service name into a protocol and
port number, and then returns a list of address structures suitable to
connect() to it.

When given just a host name, this function attempts to resolve it to a set of
network addresses, and then returns a list of these addresses in the returned
structures.

When given just a service name, this function attempts to resolve it to a
protocol and port number, and then returns a list of address structures that
represent it suitable to bind() to.

When given neither name, it generates an error.

The optional C<$hints> parameter can be passed a HASH reference to indicate
how the results are generated. It may contain any of the following four
fields:

=over 8

=item flags => INT

A bitfield containing C<AI_*> constants. At least the following flags will be
available:

=over 2

=item * C<AI_PASSIVE>

Indicates that this resolution is for a local C<bind()> for a passive (i.e.
listening) socket, rather than an active (i.e. connecting) socket.

=item * C<AI_CANONNAME>

Indicates that the caller wishes the canonical hostname (C<canonname>) field
of the result to be filled in.

=item * C<AI_NUMERICHOST>

Indicates that the caller will pass a numeric address, rather than a hostname,
and that C<getaddrinfo> must not perform a resolve operation on this name.
This flag will prevent a possibly-slow network lookup operation, and instead
return an error, if a hostname is passed.

=back

Other flags may be provided by the OS.

=item family => INT

Restrict to only generating addresses in this address family

=item socktype => INT

Restrict to only generating addresses of this socket type

=item protocol => INT

Restrict to only generating addresses for this protocol

=back

Errors are indicated by the C<$err> value returned; which will be non-zero in
numeric context, and contain a string error message as a string. The value can
be compared against any of the C<EAI_*> constants to determine what the error
is. Rather than explicitly checking, see also L<Socket::GetAddrInfo::Strict>
which provides functions that throw exceptions on errors.

If no error occurs, C<@res> will contain HASH references, each representing
one address. It will contain the following five fields:

=over 8

=item family => INT

The address family (e.g. AF_INET)

=item socktype => INT

The socket type (e.g. SOCK_STREAM)

=item protocol => INT

The protocol (e.g. IPPROTO_TCP)

=item addr => STRING

The address in a packed string (such as would be returned by pack_sockaddr_in)

=item canonname => STRING

The canonical name for the host if the C<AI_CANONNAME> flag was provided, or
C<undef> otherwise. This field will only be present on the first returned
address.

=back

=head2 ( $err, $host, $service ) = getnameinfo( $addr, $flags, $xflags )

C<getnameinfo> turns a binary socket address into a pair of human-readable
strings, containing the host name, numeric address, service name, or port
number.

The optional C<$flags> parameter is a bitfield containing C<NI_*> constants.
At least the following flags will be available:

=over 2

=item * C<NI_NUMERICHOST>

Requests that a human-readable string representation of the numeric address is
returned directly, rather than performing a name resolve operation that may
convert it into a hostname.

=item * C<NI_NUMERICSERV>

Requests that the port number be returned directly as a number representation
rather than performing a name resolve operation that may convert it into a
service name.

=item * C<NI_NAMEREQD>

If a name resolve operation fails to provide a name, then this flag will cause
C<getnameinfo> to indicate an error, rather than returning the numeric
representation as a human-readable string.

=item * C<NI_DGRAM>

Indicates that the socket address relates to a C<SOCK_DGRAM> socket, for the
services whose name differs between C<TCP> and C<UDP> protocols.

=back

Other flags may be provided by the OS.

The optional C<$xflags> parameter is a bitfield containing C<NIx_*> constants.
These are a Perl-level extension to the API, to indicate extra information.

=over 2

=item * C<NIx_NOHOST>

Indicates that the caller is not interested in the hostname of the result, so
it does not have to be converted; C<undef> will be returned as the hostname.

=item * C<NIx_NOSERV>

Indicates that the caller is not interested in the service name of the result,
so it does not have to be converted; C<undef> will be returned as the service
name.

=back

Errors are indicated by the C<$err> value returned; which will be non-zero in
numeric context, and contain a string error message as a string. The value can
be compared against any of the C<EAI_*> constants to determine what the error
is. Rather than explicitly checking, see also L<Socket::GetAddrInfo::Strict>
which provides functions that throw exceptions on errors.

=cut

=head1 EXAMPLES

=head2 Lookup for C<connect>

The C<getaddrinfo> function converts a hostname and a service name into a list
of structures, each containing a potential way to C<connect()> to the named
service on the named host.

 my %hints = ( socktype => SOCK_STREAM );
 my ( $err, @res ) = getaddrinfo( $hostname, $servicename, \%hints );
 die "Cannot getaddrinfo - $err" if $err;

 my $sock;

 foreach my $ai ( @res ) {
    my $candidate = IO::Socket->new();

    $candidate->socket( $ai->{family}, $ai->{socktype}, $ai->{protocol} )
       or next;

    $candidate->connect( $ai->{addr} )
       or next;

    $sock = $candidate;
    last;
 }

Because a list of potential candidates is returned, the C<while> loop tries
each in turn until it it finds one that succeeds both the C<socket()> and
C<connect()> calls.

This function performs the work of the legacy functions C<gethostbyname>,
C<getservbyname>, C<inet_aton> and C<pack_sockaddr_in>.

=head2 Making a human-readable string out of an address

The C<getnameinfo> function converts a socket address, such as returned by
C<getsockname> or C<getpeername>, into a pair of human-readable strings
representing the address and service name.

 my ( $err, $hostname, $servicename ) = getnameinfo( $socket->peername );
 die "Cannot getnameinfo - $err" if $err;

 print "The peer is connected from $hostname\n";

Since in this example only the hostname was used, the redundant conversion of
the port number into a service name may be omitted by passing the
C<NIx_NOSERV> flag.

 my ( $err, $hostname ) = getnameinfo( $socket->peername, 0, NIx_NOSERV );

This function performs the work of the legacy functions C<unpack_sockaddr_in>,
C<inet_ntoa>, C<gethostbyaddr> and C<getservbyport>.

=head2 Resolving hostnames into IP addresses

To turn a hostname into a human-readable plain IP address use C<getaddrinfo>
to turn the hostname into a list of socket structures, then C<getnameinfo> on
each one to make it a readable IP address again.

 my ( $err, @res ) = getaddrinfo( $hostname, "", { socktype => SOCK_RAW } );
 die "Cannot getaddrinfo - $err" if $err;

 while( my $ai = shift @res ) {
    my ( $err, $ipaddr ) = getnameinfo( $ai->{addr}, NI_NUMERICHOST, NIx_NOSERV );
    die "Cannot getnameinfo - $err" if $err;

    print "$ipaddr\n";
 }

The C<socktype> hint to C<getaddrinfo> filters the results to only include one
socket type and protocol. Without this most OSes return three combinations,
for C<SOCK_STREAM>, C<SOCK_DGRAM> and C<SOCK_RAW>, resulting in triplicate
output of addresses. The C<NI_NUMERICHOST> flag to C<getnameinfo> causes it to
return a string-formatted plain IP address, rather than reverse resolving it
back into a hostname.

This combination performs the work of the legacy functions C<gethostbyname>
and C<inet_ntoa>.

=cut

=head1 BUILDING WITHOUT XS CODE

In some environments it may be preferred not to build the XS implementation,
leaving a choice only of the core or pure-perl emulation implementations.

 $ perl Build.PL --pp

or

 $ PERL_SOCKET_GETADDRINFO_NO_BUILD_XS=1 perl Build.PL 

=head1 BUGS

=over 4

=item *

Appears to FAIL on older Darwin machines (e.g. C<osvers=8.11.1>). The failure
mode occurs in F<t/02getnameinfo.t> and appears to relate to an endian bug;
expecting to receive C<80> and instead receiving C<20480> (which is a 16-bit
C<80> byte-swapped).

=back

=head1 SEE ALSO

=over 4

=item *

L<http://tools.ietf.org/html/rfc2553> - Basic Socket Interface Extensions for
IPv6

=back

=head1 ACKNOWLEDGEMENTS

Christian Hansen <chansen@cpan.org> - for help with some XS features and Win32
build fixes.

Zefram <zefram@fysh.org> - for help with fixing some bugs in the XS code.

Reini Urban <rurban@cpan.org> - for help with older perls and more Win32
build fixes.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
