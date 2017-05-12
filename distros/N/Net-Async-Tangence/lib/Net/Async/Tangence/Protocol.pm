#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::Protocol;

use strict;
use warnings;

our $VERSION = '0.14';

use base qw( IO::Async::Stream Tangence::Stream );

use Carp;

=head1 NAME

C<Net::Async::Tangence::Protocol> - concrete implementation of
C<Tangence::Stream> for C<IO::Async>

=head1 DESCRIPTION

This subclass of L<IO::Async::Stream> provides a concrete implementation of
the L<Tangence::Stream> mixin. It is not intended to be directly used by
server implementations. Instead, it is subclassed as
L<Net::Async::Tangence::Client> and L<Net::Async::Tangence::ServerProtocol>.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $self->SUPER::_init( $params );

   $params->{on_closed} ||= undef;
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_closed} ) {
      my $on_closed = delete $params{on_closed};

      $params{on_closed} = sub {
         my ( $self ) = @_;
         $on_closed->( $self ) if $on_closed;

         $self->tangence_closed;

         if( my $parent = $self->parent ) {
            $parent->remove_child( $self );
         }
         elsif( my $loop = $self->get_loop ) {
            $loop->remove( $self );
         }
      };
   }

   $self->SUPER::configure( %params );
}

sub tangence_write
{
   my $self = shift;
   $self->write( $_[0] );
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $closed ) = @_;

   $self->tangence_readfrom( $$buffref );

   return 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
