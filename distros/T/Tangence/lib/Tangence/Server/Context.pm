#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Tangence::Server::Context;

use strict;
use warnings;

our $VERSION = '0.24';

use Carp;

use Tangence::Constants;

sub new
{
   my $class = shift;
   my ( $stream, $token ) = @_;

   return bless {
      stream => $stream,
      token  => $token,
   }, $class;
}

sub DESTROY
{
   my $self = shift;
   $self->{responded} or croak "$self never responded";
}

sub stream
{
   my $self = shift;
   return $self->{stream};
}

sub respond
{
   my $self = shift;
   my ( $message ) = @_;

   $self->{responded} and croak "$self has responded once already";

   $self->stream->respond( $self->{token}, $message );

   $self->{responded} = 1;

   return;
}

sub responderr
{
   my $self = shift;
   my ( $msg ) = @_;

   $self->respond( Tangence::Message->new( $self->stream, MSG_ERROR )
      ->pack_str( $msg )
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
