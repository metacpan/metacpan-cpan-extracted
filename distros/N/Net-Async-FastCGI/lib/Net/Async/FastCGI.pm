#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2005-2013 -- leonerd@leonerd.org.uk

package Net::Async::FastCGI;

use strict;
use warnings;

use Carp;

use base qw( IO::Async::Listener );
IO::Async::Listener->VERSION( '0.35' );

use Net::Async::FastCGI::ServerProtocol;

our $VERSION = '0.25';

# The FCGI_GET_VALUES request might ask for our maximally supported number of
# concurrent connections or requests. We don't really have an inbuilt maximum,
# so just respond these large numbers
our $MAX_CONNS = 1024;
our $MAX_REQS  = 1024;

=head1 NAME

C<Net::Async::FastCGI> - use FastCGI with L<IO::Async>

=head1 SYNOPSIS

As an adapter:

 use Net::Async::FastCGI;
 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new();

 my $fastcgi = Net::Async::FastCGI->new(
    on_request => sub {
       my ( $fastcgi, $req ) = @_;

       # Handle the request here
    }
 );

 $loop->add( $fastcgi );

 $fastcgi->listen(
    service => 1234,
    on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
    on_listen_error  => sub { die "Cannot listen - $_[-1]\n" },
 );

 $loop->run;

As a subclass:

 package MyFastCGIResponder;
 use base qw( Net::Async::FastCGI );

 sub on_request
 {
    my $self = shift;
    my ( $req ) = @_;

    # Handle the request here
 }

 ...

 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new();

 my $fastcgi;
 $loop->add( $fastcgi = MyFastCGIResponder->new( service => 1234 ) );

 $fastcgi->listen(
    service => 1234,
    on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
    on_listen_error  => sub { die "Cannot listen - $_[-1]\n" },
 );

 $loop->run;

=head1 DESCRIPTION

This module allows a program to respond asynchronously to FastCGI requests,
as part of a program based on L<IO::Async>. An object in this class represents
a single FastCGI responder that the webserver is configured to communicate
with. It can handle multiple outstanding requests at a time, responding to
each as data is provided by the program. Individual outstanding requests that
have been started but not yet finished, are represented by instances of
L<Net::Async::FastCGI::Request>.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_request $req

Invoked when a new FastCGI request is received. It will be passed a new
L<Net::Async::FastCGI::Request> object.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item on_request => CODE

CODE references for C<on_request> event handler.

=item default_encoding => STRING

Sets the default encoding used by all new requests. If not supplied then
C<UTF-8> will apply.

=back

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;
   $self->SUPER::_init( $params );

   $params->{default_encoding} = "UTF-8";
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_request} ) {
      $self->{on_request} = delete $params{on_request};
   }

   if( exists $params{default_encoding} ) {
      $self->{default_encoding} = delete $params{default_encoding};
   }

   $self->SUPER::configure( %params );
}

sub on_stream
{
   my $self = shift;
   my ( $stream ) = @_;

   $self->add_child( Net::Async::FastCGI::ServerProtocol->new(
      transport => $stream,
      fcgi      => $self,
   ) );
}

=head1 METHODS

=cut

=head2 $fcgi->listen( %args )

Start listening for connections on a socket, creating it first if necessary.

This method may be called in either of the following ways. To listen on an
existing socket filehandle:

=over 4

=item handle => IO

An IO handle referring to a listen-mode socket. This is now deprecated; use
the C<handle> key to the C<new> or C<configure> methods instead.

=back

Or, to create the listening socket or sockets:

=over 4

=item service => STRING

Port number or service name to listen on.

=item host => STRING

Optional. If supplied, the hostname will be resolved into a set of addresses,
and one listening socket will be created for each address. If not, then all
available addresses will be used.

=back

This method may also require C<on_listen_error> or C<on_resolve_error>
callbacks for error handling - see L<IO::Async::Listener> for more detail.

=cut

sub listen
{
   my $self = shift;
   my %args = @_;

   $self->SUPER::listen( %args, socktype => 'stream' );
}

sub _request_ready
{
   my $self = shift;
   my ( $req ) = @_;

   $self->invoke_event( on_request => $req );
}

sub _default_encoding
{
   my $self = shift;
   return $self->{default_encoding};
}

=head1 Limits in FCGI_GET_VALUES

The C<FCGI_GET_VALUES> FastCGI request can enquire of the responder the
maximum number of connections or requests it can support. Because this module
puts no fundamental limit on these values, it will return some arbitrary
numbers. These are given in package variables:

 $Net::Async::FastCGI::MAX_CONNS = 1024;
 $Net::Async::FastCGI::MAX_REQS  = 1024;

These variables are provided in case the containing application wishes to make
the library return different values in the request. These values are not
actually used by the library, other than to fill in the values in response of
C<FCGI_GET_VALUES>.

=head1 Using a socket on STDIN

When running a local FastCGI responder, the webserver will create a new INET
socket connected to the script's STDIN file handle. To use the socket in this
case, it should be passed as the C<handle> argument.

=head1 SEE ALSO

=over 4

=item *

L<CGI::Fast> - Fast CGI drop-in replacement of L<CGI>; single-threaded,
blocking mode.

=item *

L<http://hoohoo.ncsa.uiuc.edu/cgi/interface.html> - The Common Gateway
Interface Specification

=item *

L<http://www.fastcgi.com/devkit/doc/fcgi-spec.html> - FastCGI Specification

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
