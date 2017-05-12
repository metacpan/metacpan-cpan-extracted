#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Net::Async::HTTP::StallTimer;

use strict;
use warnings;
use base qw( IO::Async::Timer::Countdown );

our $VERSION = '0.41';

sub _init
{
   my $self = shift;
   my ( $params ) = @_;
   $self->SUPER::_init( $params );

   $self->{future} = delete $params->{future};
}

sub reason :lvalue { shift->{stall_reason} }

sub on_expire
{
   my $self = shift;

   my $conn = $self->parent;

   $self->{future}->fail( "Stalled while ${\$self->reason}", stall_timeout => );

   $conn->close_now;
}

0x55AA;
