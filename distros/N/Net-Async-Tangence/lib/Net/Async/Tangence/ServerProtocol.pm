#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::ServerProtocol;

use strict;
use warnings;

use base qw( Net::Async::Tangence::Protocol Tangence::Server );
use mro 'c3';

our $VERSION = '0.14';

use Carp;

=head1 NAME

C<Net::Async::Tangence::ServerProtocol> - C<Net::Async::Tangence::Protocol>
subclass for servers

=head1 DESCRIPTION

This subclass of L<Net::Async::Tangence::Protocol> provides additional logic
required by the server side of a connection. It is not intended to be directly
used by server implementations.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $self->registry( delete $params->{registry} );

   $params->{on_closed} ||= undef;

   $self->SUPER::_init( $params );
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_closed} ) {
      my $on_closed = $params{on_closed};
      $params{on_closed} = sub {
         my $self = shift;

         $on_closed->( $self ) if $on_closed;
      };
   }

   $self->SUPER::configure( %params );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
