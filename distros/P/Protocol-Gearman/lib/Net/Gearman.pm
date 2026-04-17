#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014,2026 -- leonerd@leonerd.org.uk

package Net::Gearman 0.05;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use base qw( IO::Socket::IP );

=head1 NAME

C<Net::Gearman> - provide a synchronous concrete Gearman implementation

=head1 DESCRIPTION

=for highlighter language=perl

This module provides a simple synchronous concrete implementation to run a
L<Protocol::Gearman::Client> or L<Protocol::Gearman::Worker> on top of. It
shouldn't be used directly; see instead

=over 2

=item *

L<Net::Gearman::Client>

=item *

L<Net::Gearman::Worker>

=back

=head1 CONSTRUCTOR

=cut

=head2 new

   $gearman = Net::Gearman->new( %args );

Returns a new C<Net::Gearman> object. Takes the same arguments as
C<IO::Socket::IP>. Sets a default value for C<PeerService> if not provided of
4730.

=cut

sub new ( $class, @args )
{
   my %args = @args == 1 ? ( PeerHost => shift @args ) : @args;

   $args{PeerService} //= 4730;

   return $class->SUPER::new( %args );
}

sub gearman_state ( $self )
{
   ${*$self}{gearman} ||= {};
}

sub new_future ( $self )
{
   return Net::Gearman::Future->new( $self );
}

sub do_read ( $self )
{
   my $buffer = $self->gearman_state->{gearman_buffer} // "";

   # TODO: consider an on_recv_packet to make this more efficient
   $self->sysread( $buffer, 8192, length $buffer );
   $self->on_recv( $buffer );

   $self->gearman_state->{gearman_buffer} = $buffer;
}

package # hide
   Net::Gearman::Future;
use base qw( Future );

sub new ( $class, $gearman )
{
   my $self = $class->SUPER::new;
   $self->set_udata( gearman => $gearman );
   return $self;
}

sub await ( $self )
{
   while( !$self->is_ready ) {
      $self->udata( 'gearman' )->do_read;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
