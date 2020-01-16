#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2020 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::Server;

use strict;
use warnings;

use IO::Async::Listener '0.36';
use base qw( IO::Async::Listener );

our $VERSION = '0.15';

use Carp;

use Net::Async::Tangence::ServerProtocol;

=head1 NAME

C<Net::Async::Tangence::Server> - serve C<Tangence> clients using C<IO::Async>

=head1 DESCRIPTION

This subclass of L<IO::Async::Listener> accepts L<Tangence> client
connections.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item registry => Tangence::Registry

The L<Tangence::Registry> for the server's objects.

=back

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $params->{handle_constructor} = sub {
      my $self = shift;

      return Net::Async::Tangence::ServerProtocol->new(
         registry => $self->{registry},
         on_closed => $self->_capture_weakself( sub {
            my $self = shift;
            $self->remove_child( $_[0] );
         } ),
      );
   };

   $self->SUPER::_init( $params );

   $self->{registry} = delete $params->{registry} if exists $params->{registry};
}

sub on_accept
{
   my $self = shift;
   my ( $conn ) = @_;

   $self->add_child( $conn );
}

# Useful for testing
sub make_new_connection
{
   my $self = shift;
   my ( $sock ) = @_;

   # Mass cheating
   my $conn = $self->{handle_constructor}->( $self );

   $conn->configure( handle => $sock );
   $self->on_accept( $conn );

   return $conn;
}

# More testing utilities
sub accept_stdio
{
   my $self = shift;

   my $conn = $self->{handle_constructor}->( $self );

   $conn->configure(
      read_handle  => \*STDIN,
      write_handle => \*STDOUT,
   );
   $self->on_accept( $conn );

   return $conn;
}

=head1 OVERRIDEABLE METHODS

The following methods are provided but intended to be overridden if the
implementing class wishes to provide different behaviour from the default.

=cut

=head2 conn_rootobj

   $rootobj = $server->conn_rootobj( $conn, $identity )

Invoked when a C<GETROOT> message is received from the client, this method
should return a L<Tangence::Object> as root object for the connection.

The default implementation will return the object with ID 1; i.e. the first
object created in the registry.

=cut

sub conn_rootobj
{
   my $self = shift;
   return $self->{registry}->get_by_id( 1 );
}

=head2 conn_permits_registry

   $allow = $server->conn_permits_registry( $conn )

Invoked when a C<GETREGISTRY> message is received from the client on the given
connection object. This method should return a boolean to indicate whether the
client is allowed to access the object registry.

The default implementation always permits this, but an overridden method may
decide to disallow it in some situations. When disabled, a client will not be
able to gain access to any serverside objects other than the root object, and
(recursively) any other objects returned by methods, events or properties on
objects already known. This can be used as a security mechanism.

=cut

sub conn_permits_registry
{
   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
