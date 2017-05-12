#
# $Id: LLC.pm 20 2015-01-13 18:34:19Z gomor $
#
package Net::Frame::Layer::LLC;
use strict;
use warnings;

our $VERSION = '1.03';

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_LLC_HDR_LEN
      NF_LLC_DSAP_STP
      NF_LLC_SSAP_STP
      NF_LLC_DSAP_SNAP
      NF_LLC_SSAP_SNAP
      NF_LLC_DSAP_IPX
      NF_LLC_SSAP_IPX
      NF_LLC_DSAP_HPEXTLLC
      NF_LLC_SSAP_HPEXTLLC
      NF_LLC_SNAP_HDR_LEN
      NF_LLC_SNAP_OUI_CISCO
      NF_LLC_SNAP_PID_CDP
      NF_LLC_SNAP_PID_STP
      NF_LLC_SNAP_PID_IPX
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_LLC_HDR_LEN   => 3;
use constant NF_LLC_DSAP_STP  => 0x21;
use constant NF_LLC_SSAP_STP  => 0x21;
use constant NF_LLC_DSAP_SNAP => 0x55;
use constant NF_LLC_SSAP_SNAP => 0x55;
use constant NF_LLC_DSAP_IPX => 0x70;
use constant NF_LLC_SSAP_IPX => 0x70;
use constant NF_LLC_DSAP_HPEXTLLC => 0x7c;
use constant NF_LLC_SSAP_HPEXTLLC => 0x7c;

use constant NF_LLC_SNAP_HDR_LEN   => 5;
use constant NF_LLC_SNAP_OUI_CISCO => 0x00000c;
use constant NF_LLC_SNAP_PID_CDP   => 0x2000;
use constant NF_LLC_SNAP_PID_STP   => 0x010b;
use constant NF_LLC_SNAP_PID_IPX   => 0x8137;

our @AS = qw(
   dsap
   ig
   ssap
   cr
   control
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

require Bit::Vector;

sub new {
   shift->SUPER::new(
      dsap    => NF_LLC_DSAP_SNAP,
      ig      => 1,
      ssap    => NF_LLC_SSAP_SNAP,
      cr      => 1,
      control => 0x03,
      @_,
   );
}

sub getLength { NF_LLC_HDR_LEN }

sub pack {
   my $self = shift;

   my $dsap = Bit::Vector->new_Dec(7, $self->[$__dsap]);
   my $ig   = Bit::Vector->new_Dec(1, $self->[$__ig]);
   my $ssap = Bit::Vector->new_Dec(7, $self->[$__ssap]);
   my $cr   = Bit::Vector->new_Dec(1, $self->[$__cr]);
   my $v16  = $dsap->Concat_List($ig, $ssap, $cr);

   $self->[$__raw] = $self->SUPER::pack('nC',
      $v16->to_Dec,
      $self->[$__control],
   ) or return undef;

   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($dsapIgSsapCr, $control, $payload) =
      $self->SUPER::unpack('nC a*', $self->[$__raw])
         or return undef;

   my $v16 = Bit::Vector->new_Dec(16, $dsapIgSsapCr);
   $self->[$__dsap] = $v16->Chunk_Read(7, 9);
   $self->[$__ig]   = $v16->Chunk_Read(1, 8);
   $self->[$__ssap] = $v16->Chunk_Read(7, 1);
   $self->[$__cr]   = $v16->Chunk_Read(1, 0);

   $self->[$__control] = $control;

   $self->[$__payload] = $payload;

   $self;
}

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   my $types = {
      NF_LLC_DSAP_STP()      => 'STP',
      NF_LLC_DSAP_IPX()      => 'IPX',
      NF_LLC_DSAP_SNAP()     => 'LLC::SNAP',
      NF_LLC_DSAP_HPEXTLLC() => 'HPEXTLLC',
   };

   $types->{$self->[$__dsap]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: dsap:0x%02x  ig:%d  ssap:0x%02x  cr:%d  control:0x%02x",
      $self->[$__dsap], $self->[$__ig], $self->[$__ssap], $self->[$__cr],
      $self->[$__control];
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLC - Logical-Link Control layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLC qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::LLC->new(
      dsap    => NF_LLC_DSAP_SNAP,
      ig      => 1,
      ssap    => NF_LLC_SSAP_SNAP,
      cr      => 1,
      control => 0x03,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLC->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Logical-Link Control layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<dsap> - 7 bits

=item B<ig> - 1 bit

=item B<ssap> - 7 bits

=item B<cr> - 1 bit

=item B<control> - 8 bits

=back

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<computeChecksums>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::LLC qw(:consts);

=over 4

=item B<NF_LLC_HDR_LEN>

LLC header length.

=item B<NF_LLC_DSAP_SNAP>

=item B<NF_LLC_DSAP_STP>

Dsap attribute constants.

=item B<NF_LLC_SSAP_SNAP>

=item B<NF_LLC_SSAP_STP>

Ssap attribute constants.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
