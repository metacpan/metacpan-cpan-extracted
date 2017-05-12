#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2014 -- leonerd@leonerd.org.uk

package Net::LibAsyncNS;

use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Net::LibAsyncNS> - a Perl wrapper around F<libasyncns>

=head1 SYNOPSIS

 use Net::LibAsyncNS;
 use Socket qw( SOCK_RAW );

 my $asyncns = Net::LibAsyncNS->new( 1 );

 # By specifying this socktype hint, we only get one result per address family
 my %hints = ( socktype => SOCK_RAW );

 my $query = $asyncns->getaddrinfo( "localhost", undef, \%hints );

 while( $asyncns->getnqueries ) {
    $asyncns->wait( 1 );

    if( $query->isdone ) {
       my ( $err, @res ) = $asyncns->getaddrinfo_done( $query );
       die "getaddrinfo - $err" if $err;

       foreach my $res ( @res ) {
          printf "family=%d, addr=%v02x\n", $res->{family}, $res->{addr};
       }
    }
 }

=head1 DESCRIPTION

The name resolver functions C<getaddrinfo> and C<getnameinfo> as provided by
most C libraries are blocking functions; they will perform their work and
return an answer when it is ready. This makes it hard to use these name
resolvers in asynchronous or non-blocking code.

The F<libasyncns> library provides a way to invoke these library functions
from within an asynchronous or non-blocking program.  Individual resolver
queries are made by calling a function which returns an object representing
an outstanding query (a kind of future). A filehandle is provided by the
resolver to watch for readability; when it is readable, a function should be
called to collect completed queries. The example in the SYNOPSIS above does
not demonstrate this; see the EXAMPLES section below for one that does.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $asyncns = Net::LibAsyncNS->new( $n_proc )

Construct a new C<Net::LibAsyncNS> object. It will be initialised with
C<$n_proc> processes or threads to handle nameserver lookups.

=cut

=head1 METHODS

=cut

# The following documents the various XS-implemented methods in LibAsyncNS.xs in
# the same order

=head2 $fd = $asyncns->fd

Returns a file descriptor number to poll for readability on.

=cut

=head2 $handle = $asyncns->new_handle_for_fd

Returns a new C<IO::Handle> object wrapping the underlying file descriptor.
Note that the handle is I<not> cached; a new object is created each time this
method is called. For well-behaved results, this should only be called once.

=cut

sub new_handle_for_fd
{
   my $self = shift;
   require IO::Handle;
   return IO::Handle->new->fdopen( $self->fd, "<" );
}

=head2 $success = $asyncns->wait( $block )

Wait for more queries to be ready. If C<$block> is true, this method will
block until at least one query is ready, if false it will process any pending
IO without blocking. It returns true if the operation was successful or false
if an IO error happened; C<$!> will be set in this case.

=cut

=head2 $n = $asyncns->getnqueries

Return the number of outstanding queries.

=cut

=head2 $q = $asyncns->getaddrinfo( $host, $service, $hints )

Starts an asynchronous C<getaddrinfo> resolution on the given C<$host> and
C<$service> names. If provided, C<$hints> should be a HASH reference where the
following keys are recognised:

=over 8

=item flags => INT

=item family => INT

=item socktype => INT

=item protocol => INT

=back

=cut

=head2 ( $err, @res ) = $asyncns->getaddrinfo_done( $q )

Finishes a C<getaddrinfo> resolution, returning an error code, and a list of
results. Each result will be a HASH reference containing the following keys:

=over 8

=item family => INT

=item socktype => INT

=item protocol => INT

Socket type values to pass to C<socket>

=item addr => STRING

Address to pass to C<connect>

=item canonname => STRING

If requested, the canonical hostname for this address

=back

=cut

=head2 $q = $asyncns->getnameinfo( $addr, $flags, $wanthost, $wantserv )

Starts an asynchronous C<getnameinfo> resolution on the given address. The
C<$wanthost> and C<$wantserv> booleans indicate if the hostname or service
name are required.

=cut

=head2 ( $err, $host, $service ) = $asyncns->getnameinfo_done( $q )

Finishes a C<getnameinfo> resolution, returning an error code, the hostname
and service name, if requested.

=cut

=head2 $q = $asyncns->res_query( $dname, $class, $type )

=head2 $q = $asyncns->res_search( $dname, $class, $type )

Starts an asynchronous C<res_query> or C<res_search> resolution on the given
domain name, class and type.

=head2 $answer = $asyncns->res_done( $q )

Finishes a C<res_query> or C<res_search> resolution, returning the answer in a
packed string, or C<undef> if it fails. If it fails C<$!> will contain the
error details.

=head2 $done = $asyncns->isdone( $q )

Returns true if the given query is ready.

=cut

=head2 $q = $asyncns->getnext

Returns the next query object that is completed, or C<undef> if none are ready
yet. This will only yet be valid after calling the C<wait> method at least
once.

=head2 $asyncns->cancel( $q )

Cancels a currently outstanding query. After this is called, the query in
C<$q> should not be further accessed, as memory associated with it will have
been reclaimed.

=cut

=head2 $asyncns->setuserdata( $q, $data )

Stores an arbitrary Perl scalar with the query. It can later be retrieved
using C<getuserdata>.

=cut

=head2 $data = $asyncns->getuserdata( $q )

Returns the Perl scalar previously stored with the query, or C<undef> if no
value has yet been set.

=cut

=head1 CONSTANTS

The following constants are provided by L<Net::LibAsyncNS::Constants>.

Flags for C<getaddrinfo>:

 AI_PASSIVE
 AI_CANONNAME
 AI_NUMERICHOST
 AI_NUMERICSERV

Error values:

 EAI_BADFLAGS
 EAI_NONAME
 EAI_AGAIN
 EAI_FAIL
 EAI_NODATA
 EAI_FAMILY
 EAI_SERVICE
 EAI_SOCKTYPE
 EAI_ADDRFAMILY
 EAI_MEMORY

Flags for C<getnameinfo>:

 NI_NUMERICHOST
 NI_NUMERICSERV
 NI_NAMEREQD
 NI_DGRAM

=cut

=head1 QUERY OBJECTS

The following methods are available on query objects, returned by
C<getaddrinfo> and C<getnameinfo>.

=cut

=head2 $asyncns = $query->asyncns

Returns the underlying C<Net::LibAsyncNS> object backing the query

=cut

=head2 $done = $query->isdone

=head2 $query->setuserdata( $data )

=head2 $data = $query->getuserdata

Shortcuts to the equivalent method on the underlying C<Net::LibAsyncNS> object

=cut

sub Net::LibAsyncNS::Query::isdone
{
   my $q = shift;
   $q->asyncns->isdone( $q );
}

sub Net::LibAsyncNS::Query::setuserdata
{
   my $q = shift;
   $q->asyncns->setuserdata( $q, @_ );
}

sub Net::LibAsyncNS::Query::getuserdata
{
   my $q = shift;
   $q->asyncns->getuserdata( $q );
}

=head1 EXAMPLES

=head2 Multiple Queries

The SYNOPSIS example only has one outstanding query. To wait for multiple
queries to complete, the C<getnext> method can be used. Per-query context data
can be stored in the query itself by using the C<setuserdata> and
C<getuserdata> accessors.

 use Net::LibAsyncNS;
 use Socket qw( SOCK_RAW );

 my $asyncns = Net::LibAsyncNS->new( 1 );

 my %hints = ( socktype => SOCK_RAW );
 my @hosts = qw( some hostnames here );

 foreach my $host ( @hosts ) {
    my $query = $asyncns->getaddrinfo( $host, undef, \%hints );
    $query->setuserdata( $host );
 }

 while( $asyncns->getnqueries ) {
    $asyncns->wait( 1 ) or die "asyncns_wait: $!";

    while( my $query = $asyncns->getnext ) {
       my ( $err, @res ) = $asyncns->getaddrinfo_done( $query );
       my $host = $query->getuserdata;

       print "$host - $err\n" and next if $err;

       foreach my $res ( @res ) {
          printf "%s is: family=%d, addr=%v02x\n", 
             $host, $res->{family}, $res->{addr};
       }
    }
 }

In this example, the per-query data stored by C<setuserdata> is just the
hostname, but any Perl scalar may be stored, such as a HASH ref containing
many keys, or CODE ref to a callback function of some kind.

=head2 Non-blocking IO

The examples above wait synchronously for the query/queries to complete, in
the C<wait> method. However, most of the point of this library is to allow
asynchronous resolver calls to mix with other asynchronous and non-blocking
code. This is achieved by the containing program waiting for a filehandle to
become readable, and to call C<< $asyncns->wait( 0 ) >> when it is.

The following example shows integration with a simple C<IO::Poll>-based
program.

 use IO::Poll;
 use Net::LibAsyncNS;
 use Socket qw( SOCK_RAW );

 my $asyncns = Net::LibAsyncNS->new( 1 );
 my %hints = ( socktype => SOCK_RAW );

 my @hosts = qw( some hostnames here );

 foreach my $host ( @hosts ) {
    my $query = $asyncns->getaddrinfo( $host, undef, \%hints );
    $query->setuserdata( $host );
 }

 my $asyncns_handle = $asyncns->new_handle_for_fd;

 my $poll = IO::Poll->new;
 $poll->mask( $asyncns_handle => POLLIN );

 while( $asyncns->getnqueries ) {
    defined $poll->poll or die "poll() - $!";

    if( $poll->events( $asyncns_handle ) ) {
       while( my $query = $asyncns->getnext ) {
          my ( $err, @res ) = $asyncns->getaddrinfo_done( $query );
          my $host = $query->getuserdata;

          print "$host - $err\n" and next if $err;

          foreach my $res ( @res ) {
             printf "%s is: family=%d, addr=%v02x\n", 
                $host, $res->{family}, $res->{addr};
          }
       }
    }
 }

=head1 SEE ALSO

=over 4

=item *

L<http://0pointer.de/lennart/projects/libasyncns> is a C library for
Linux/Unix for executing name service queries asynchronously. It is an
asynchronous wrapper around getaddrinfo(3), getnameinfo(3), res_query(3) and
res_search(3) from libc and libresolv.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
