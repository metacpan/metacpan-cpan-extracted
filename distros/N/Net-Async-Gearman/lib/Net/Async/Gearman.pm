#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Net::Async::Gearman;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw( IO::Async::Stream Protocol::Gearman );

=head1 NAME

C<Net::Async::Gearman> - use Gearman with L<IO::Async>

=head1 DESCRIPTION

This module provides an L<IO::Async>-based wrapper around
L<Protocol::Gearman>. It shouldn't be used directly; see instead

=over 2

=item *

L<Net::Async::Gearman::Client>

=back

=cut

=head1 METHODS

=cut

=head2 $gearman->connect( %args ) ==> ( $gearman )

Connects to the server. Takes the same arguments as L<IO::Async::Handle>'s
C<connect> method, but additionally sets a default service name of port 4730.

=cut

sub connect
{
   my $self = shift;
   my %args = @_;

   $self->SUPER::connect(
      service => "4730",
      %args,
   );
}

sub new_future
{
   my $self = shift;
   return $self->loop->new_future;
}

sub send
{
   my $self = shift;
   my ( $bytes ) = @_;

   $self->write( $bytes );
}

# geaman_state is OK

sub on_read
{
   my $self = shift;
   my ( $buffref, $eof ) = @_;

   $self->Protocol::Gearman::on_read( $$buffref );
   return 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
