#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package Tangence::Client;

use strict;
use warnings;

use base qw( Tangence::Stream );

our $VERSION = '0.24';

use Carp;

use Tangence::Constants;
use Tangence::Types;
use Tangence::ObjectProxy;

use Future;

use List::Util qw( max );

use constant VERSION_MINOR_MIN => 2;

=head1 NAME

C<Tangence::Client> - mixin class for building a C<Tangence> client

=head1 SYNOPSIS

This class is a mixin, it cannot be directly constructed

 package Example::Client;
 use base qw( Base::Client Tangence::Client );

 sub connect
 {
    my $self = shift;
    $self->SUPER::connect( @_ );

    $self->tangence_connected;

    wait_for { defined $self->rootobj };
 }

 sub tangence_write
 {
    my $self = shift;
    $self->write( $_[0] );
 }

 sub on_read
 {
    my $self = shift;
    $self->tangence_readfrom( $_[0] );
 }

 package main;

 my $client = Example::Client->new;
 $client->connect( "server.location.here" );

 my $rootobj = $client->rootobj;

=head1 DESCRIPTION

This module provides mixin to implement a C<Tangence> client connection. It
should be mixed in to an object used to represent a single connection to a
server. It provides a central location in the client to store object proxies,
including to the root object and the registry, and coordinates passing
messages between the server and the object proxies it contains.

This is a subclass of L<Tangence::Stream> which provides implementations of
the required C<handle_request_> methods. A class mixing in C<Tangence::Client>
must still provide the C<tangence_write> method required for sending data to
the server.

For an example of a class that uses this mixin, see
L<Net::Async::Tangence::Client>.

=cut

=head1 PROVIDED METHODS

The following methods are provided by this mixin.

=cut

# Accessors for Tangence::Message decoupling
sub objectproxies { shift->{objectproxies} ||= {} }

=head2 rootobj

   $rootobj = $client->rootobj

Returns a L<Tangence::ObjectProxy> to the server's root object

=cut

sub rootobj
{
   my $self = shift;
   $self->{rootobj} = shift if @_;
   return $self->{rootobj};
}

=head2 registry

   $registry = $client->registry

Returns a L<Tangence::ObjectProxy> to the server's object registry

=cut

sub registry
{
   my $self = shift;
   $self->{registry} = shift if @_;
   return $self->{registry};
}

sub on_error
{
   my $self = shift;
   $self->{on_error} = shift if @_;
   return $self->{on_error};
}

=head2 tangence_connected

   $client->tangence_connected( %args )

Once the base connection to the server has been established, this method
should be called to perform the initial work of requesting the root object and
the registry.

It takes the following named arguments:

=over 8

=item do_init => BOOL

Ignored. Maintained for compatibility with previous version that allowed this
to be disabled.

=item on_root => CODE

Optional callback to be invoked once the root object has been returned. It
will be passed a L<Tangence::ObjectProxy> to the root object.

 $on_root->( $rootobj )

=item on_registry => CODE

Optional callback to be invoked once the registry has been returned. It will
be passed a L<Tangence::ObjectProxy> to the registry.

 $on_registry->( $registry )

=item version_minor_min => INT

Optional minimum minor version to negotiate with the server. This can be used
to require a higher minimum version than the client module itself supports, in
case the application requires features in a newer version than that.

=back

=cut

sub tangence_connected
{
   my $self = shift;
   my %args = @_;

   my $version_minor_min = max( VERSION_MINOR_MIN, $args{version_minor_min} || 0 );

   $self->request(
      request => Tangence::Message->new( $self, MSG_INIT )
         ->pack_int( VERSION_MAJOR )
         ->pack_int( VERSION_MINOR )
         ->pack_int( $version_minor_min ),

      on_response => sub {
         my ( $message ) = @_;
         my $code = $message->code;

         if( $code == MSG_INITED ) {
            my $major = $message->unpack_int();
            my $minor = $message->unpack_int();

            $self->minor_version( $minor );
            $self->tangence_initialised( %args );
         }
         elsif( $code == MSG_ERROR ) {
            my $msg = $message->unpack_str();
            print STDERR "Cannot initialise stream - error $msg";
         }
         else {
            print STDERR "Cannot initialise stream - code $code\n";
         }
      },
   );
}

sub tangence_initialised
{
   my $self = shift;
   my %args = @_;

   my $request = Tangence::Message->new( $self, MSG_GETROOT );
   TYPE_ANY->pack_value( $request, $self->identity );

   $self->request(
      request => $request,

      on_response => sub {
         my ( $message ) = @_;
         my $code = $message->code;

         if( $code == MSG_RESULT ) {
            $self->rootobj( TYPE_OBJ->unpack_value( $message ) );
            $args{on_root}->( $self->rootobj ) if $args{on_root};
         }
         elsif( $code == MSG_ERROR ) {
            my $msg = $message->unpack_str();
            print STDERR "Cannot get root object - error $msg";
         }
         else {
            print STDERR "Cannot get root object - code $code\n";
         }
      }
   );

   $self->request(
      request => Tangence::Message->new( $self, MSG_GETREGISTRY ),

      on_response => sub {
         my ( $message ) = @_;
         my $code = $message->code;

         if( $code == MSG_RESULT ) {
            $self->registry( TYPE_OBJ->unpack_value( $message ) );
            $args{on_registry}->( $self->registry ) if $args{on_registry};
         }
         elsif( $code == MSG_ERROR ) {
            my $msg = $message->unpack_str();
            print STDERR "Cannot get registry - error $msg";
         }
         else {
            print STDERR "Cannot get registry - code $code\n";
         }
      }
   );
}

sub handle_request_EVENT
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $objid = $message->unpack_int();

   $self->respond( $token, Tangence::Message->new( $self, MSG_OK ) );

   if( my $obj = $self->objectproxies->{$objid} ) {
      $obj->handle_request_EVENT( $message );
   }
}

sub handle_request_UPDATE
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $objid = $message->unpack_int();

   $self->respond( $token, Tangence::Message->new( $self, MSG_OK ) );

   if( my $obj = $self->objectproxies->{$objid} ) {
      $obj->handle_request_UPDATE( $message );
   }
}

sub handle_request_DESTROY
{
   my $self = shift;
   my ( $token, $message ) = @_;

   my $objid = $message->unpack_int();

   if( my $obj = $self->objectproxies->{$objid} ) {
      $obj->destroy;
      delete $self->objectproxies->{$objid};
   }

   $self->respond( $token, Tangence::Message->new( $self, MSG_OK ) );
}

sub get_by_id
{
   my $self = shift;
   my ( $id ) = @_;

   return $self->objectproxies->{$id} if exists $self->objectproxies->{$id};

   croak "Have no proxy of object id $id";
}

sub make_proxy
{
   my $self = shift;
   my ( $id, $classname, $smashdata ) = @_;

   if( exists $self->objectproxies->{$id} ) {
      croak "Already have an object id $id";
   }

   my $class;
   if( defined $classname ) {
      $class = $self->peer_hasclass->{$classname}->[0];
      defined $class or croak "Cannot construct a proxy for class $classname as no meta exists";
   }

   my $obj = $self->objectproxies->{$id} =
      Tangence::ObjectProxy->new(
         client => $self,
         id     => $id,

         class => $class,

         on_error => $self->on_error,
      );

   $obj->grab( $smashdata ) if defined $smashdata;

   return $obj;
}

=head1 SUBCLASSING METHODS

These methods are intended for implementation classes to override.

=cut

=head2 new_future

   $f = $client->new_future

Returns a new L<Future> instance for basing asynchronous operations on.

=cut

sub new_future
{
   return Future->new;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
