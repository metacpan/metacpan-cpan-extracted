#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2025 -- leonerd@leonerd.org.uk

package Net::Async::ArtNet 0.04;

use v5.14;
use warnings;

use base qw( IO::Async::Socket );

=head1 NAME

C<Net::Async::ArtNet> - use Art-Net with C<IO::Async>

=head1 SYNOPSIS

   use IO::Async::Loop;
   use Net::Async::ArtNet;

   my $loop = IO::Async::Loop->new;

   $loop->add( Net::Async::ArtNet->new(
      on_dmx => sub {
         my $self = shift;
         my ( $seq, $phy, $universe, $data ) = @_;

         return unless $phy == 0 and $universe == 0;

         my $ch10 = $data->[10 - 1];  # DMX channels are 1-indexed
         print "Channel 10 now set to: $ch10\n";
      }
   ) );

   $loop->run;

=head1 DESCRIPTION

This object class allows you to use the Art-Net protocol with C<IO::Async>.
It receives Art-Net frames containing DMX data.

=cut

=head1 EVENTS

=head2 on_dmx $seq, $phy, $uni, $data

A new set of DMX control values has been received. C<$seq> contains the
sequence number from the packet, C<$phy> and C<$uni> the physical and universe
numbers, and C<$data> will be an ARRAY reference containing up to 512 DMX
control values.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>.
Additionally, CODE references to set callbacks for events may be passed.

=over 8

=item family  => INT or STRING

=item host    => INT or STRING 

=item service => INT or STRING

Optional. C<getaddrinfo> parameters to create socket listen for Art-Net
packets on.

=item port => INT or STRING

Synonym for C<service> parameter.

=back

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   $self->{service} = 0x1936; # Art-Net
}

sub configure
{
   my $self = shift;
   my %params = @_;

   $params{service} = delete $params{port} if exists $params{port};

   foreach (qw( family host service on_dmx )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

sub on_recv
{
   my $self = shift;
   my ( $packet ) = @_;

   my ( $magic, $opcode, $verhi, $verlo ) =
      unpack( "a8 v C C", substr $packet, 0, 12, "" );

   return unless $magic eq "Art-Net\0";
   return unless $verhi == 0 and $verlo == 14;

   if( $opcode == 0x5000 ) {
      my ( $seq, $phy, $universe, $data ) =
         unpack( "C C v xx a*", $packet );
      $self->maybe_invoke_event( on_dmx => $seq, $phy, $universe, [ unpack "C*", $data ] );
   }
}

sub _add_to_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   if( !defined $self->read_handle ) {
      return $self->bind(
         ( map { $_, $self->{$_} } qw( family host service ) ),
         socktype => "dgram",
      )->get; # Blocking call, but numeric lookup so should be OK
   }

   $self->SUPER::_add_to_loop( @_ );
}

=head1 SEE ALSO

=over 4

=item *

L<http://en.wikipedia.org/wiki/Art-Net> - Art-Net - Wikipedia

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
