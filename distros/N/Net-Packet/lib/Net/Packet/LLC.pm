#
# $Id: LLC.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::LLC;
use strict;
use warnings;

require Net::Packet::Layer3;
our @ISA = qw(Net::Packet::Layer3);

use Net::Packet::Consts qw(:llc :layer);
require Bit::Vector;

our @AS = qw(
   dsap
   ig
   ssap
   cr
   control
   oui
   pid
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      dsap    => NP_LLC_DSAP_SNAP,
      ig      => 1,
      ssap    => NP_LLC_SSAP_SNAP,
      cr      => 1,
      control => 0x03,
      oui     => NP_LLC_OUI_CISCO,
      pid     => NP_LLC_PID_CDP,
      @_,
   );
}

sub getLength { NP_LLC_HDR_LEN }

sub pack {
   my $self = shift;

   my $dsap = Bit::Vector->new_Dec(7, $self->[$__dsap]);
   my $ig   = Bit::Vector->new_Dec(1, $self->[$__ig]);
   my $ssap = Bit::Vector->new_Dec(7, $self->[$__ssap]);
   my $cr   = Bit::Vector->new_Dec(1, $self->[$__cr]);
   my $v16  = $dsap->Concat_List($ig, $ssap, $cr);

   my $oui = Bit::Vector->new_Dec(24, $self->[$__oui]);

   $self->[$__raw] = $self->SUPER::pack('nCB24n',
      $v16->to_Dec,
      $self->[$__control],
      $oui->to_Bin,
      $self->[$__pid],
   ) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($dsapIgSsapCr, $control, $oui, $pid, $payload) =
      $self->SUPER::unpack('nCB24n a*', $self->[$__raw])
         or return undef;

   my $v16 = Bit::Vector->new_Dec(16, $dsapIgSsapCr);
   $self->[$__dsap] = $v16->Chunk_Read(7, 0);
   $self->[$__ig]   = $v16->Chunk_Read(1, 7);
   $self->[$__ssap] = $v16->Chunk_Read(7, 8);
   $self->[$__cr]   = $v16->Chunk_Read(1, 15);

   $self->[$__control] = $control;

   my $v24 = Bit::Vector->new_Bin(24, $oui);
   $self->[$__oui] = $v24->to_Dec;

   $self->[$__pid]     = $pid;
   $self->[$__payload] = $payload;

   1;
}

sub encapsulate {
   my $types = {
      NP_LLC_PID_CDP() => NP_LAYER_CDP(),
      NP_LLC_PID_STP() => NP_LAYER_STP(),
   };

   $types->{shift->[$__pid]} || NP_LAYER_UNKNOWN();
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   sprintf "$l:+$i: dsap:0x%02x  ig:%d  ssap:0x%02x  cr:%d  control:0x%02x\n".
           "$l: $i: oui:0x%06x  pid:0x%04x",
      $self->[$__dsap], $self->[$__ig], $self->[$__ssap], $self->[$__cr],
      $self->[$__control], $self->[$__oui], $self->[$__pid];
}

1;

__END__

=head1 NAME

Net::Packet::LLC - Logical-Link Control layer 3 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:llc);
   require Net::Packet::LLC;

   # Build a layer
   my $layer = Net::Packet::LLC->new(
      dsap    => NP_LLC_DSAP_SNAP,
      ig      => 1,
      ssap    => NP_LLC_SSAP_SNAP,
      cr      => 1,
      control => 0x03,
      oui     => NP_LLC_OUI_CISCO,
      pid     => NP_LLC_PID_CDP,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::LLC->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Logical-Link Control layer.

See also B<Net::Packet::Layer> and B<Net::Packet::Layer3> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<dsap> - 7 bits

=item B<ig> - 1 bit

=item B<ssap> - 7 bits

=item B<cr> - 1 bit

=item B<control> - 8 bits

=item B<oui> - 24 bits

=item B<pid> - 16 bits

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

dsap:    NP_LLC_DSAP_SNAP

ig:      1

ssap:    NP_LLC_SSAP_SNAP

cr:      1

control: 0x03

oui:     NP_LLC_OUI_CISCO

pid:     NP_LLC_PID_CDP


=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:llc);

=over 4

=item B<NP_LLC_HDR_LEN>

LLC header length.

=item B<NP_LLC_OUI_CISCO>

Oui attribute constants.

=item B<NP_LLC_PID_CDP>

=item B<NP_LLC_PID_STP>

Pid attribute constants.

=item B<NP_LLC_DSAP_SNAP>

Dsap attribute constants.

=item B<NP_LLC_SSAP_SNAP>

Ssap attribute constants.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
