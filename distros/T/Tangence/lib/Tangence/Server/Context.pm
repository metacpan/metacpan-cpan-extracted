#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.66;

package Tangence::Server::Context 0.30;
class Tangence::Server::Context;

use Carp;

use Tangence::Constants;

field $stream :param :reader;
field $token  :param;

sub BUILDARGS ( $class, $stream, $token )
{
   return ( stream => $stream, token => $token );
}

field $responded;

# TODO: Object::Pad probably should do this bit
method DESTROY
{
   $responded or croak "$self never responded";
}

method respond ( $message )
{
   $responded and croak "$self has responded once already";

   $stream->respond( $token, $message );

   $responded = 1;

   return;
}

method responderr ( $msg )
{
   chomp $msg; # In case of simple  ->responderr( $@ );

   $self->respond( Tangence::Message->new( $stream, MSG_ERROR )
      ->pack_str( $msg )
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
