#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::Server;

use strict;
use warnings;

use IO::Async::Listener '0.36';
use base qw( IO::Async::Listener );

our $VERSION = '0.14';

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

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
