#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b20bc-200e-11de-bdc9-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::LineOfSightResponse;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::CIGI::AtmosphereControl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

# Preloaded methods go here.

=head1 NAME

Rinchi::CIGIPP::LineOfSightResponse - Perl extension for the Common Image 
Generator Interface - Line Of Sight Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::LineOfSightResponse;
  my $los_resp = Rinchi::CIGIPP::LineOfSightResponse->new();

  $packet_type = $los_resp->packet_type();
  $packet_size = $los_resp->packet_size();
  $request_ident = $los_resp->request_ident(23176);
  $host_frame_number_lsn = $los_resp->host_frame_number_lsn(15);
  $visible = $los_resp->visible(Rinchi::CIGIPP->Occluded);
  $entity_ident_valid = $los_resp->entity_ident_valid(Rinchi::CIGIPP->Invalid);
  $valid = $los_resp->valid(Rinchi::CIGIPP->Invalid);
  $response_count = $los_resp->response_count(68);
  $entity_ident = $los_resp->entity_ident(9383);
  $range = $los_resp->range(45.403);

=head1 DESCRIPTION

The Line of Sight Response packet is used in response to both the Line of Sight 
Segment Request and Line of Sight Vector Request packets. This packet contains 
the distance from the Line of Sight (LOS) segment or vector source point to the 
point of intersection with a polygon surface. The packet is sent when the 
Request Type attribute of the request packet is set to Basic (0).

A Line of Sight Response packet will be sent for each intersection along the 
LOS segment or vector. The Response Count attribute will contain the total 
number of responses that are being returned. This will allow the Host to 
determine when all response packets for the given request have been received.

If the Update Period attribute of the originating Line of Sight Segment Request 
or Line of Sight Vector Request packet was set to a value greater than zero, 
then the Host Frame Number LSN attribute of each corresponding Line of Sight 
Response packet must contain the least significant nybble of the Host Frame 
Number value last received by the IG before the range is calculated. The Host 
may correlate this LSN to an eyepoint position or may use the value to 
determine latency.

=head2 EXPORT

None by default.

#==============================================================================

=item new $los_resp = Rinchi::CIGIPP::LineOfSightResponse->new()

Constructor for Rinchi::LineOfSightResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b20bc-200e-11de-bdc9-001c25551abc',
    '_Pack'                                => 'CCSCCSd',
    '_Swap1'                               => 'CCvCCvVV',
    '_Swap2'                               => 'CCnCCnNN',
    'packetType'                           => 104,
    'packetSize'                           => 16,
    'requestIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields hostFrameNumberLSN, unused73, visible, entityIdentValid, and valid.
    'hostFrameNumberLSN'                   => 0,
    'visible'                              => 0,
    'entityIdentValid'                     => 0,
    'valid'                                => 0,
    'responseCount'                        => 0,
    'entityIdent'                          => 0,
    'range'                                => 0,
  };

  if (@_) {
    if (ref($_[0]) eq 'ARRAY') {
      $self->{'_Buffer'} = $_[0][0];
    } elsif (ref($_[0]) eq 'HASH') {
      foreach my $attr (keys %{$_[0]}) {
        $self->{"_$attr"} = $_[0]->{$attr} unless ($attr =~ /^_/);
      }
    }        
  }

  bless($self,$class);
  return $self;
}

#==============================================================================

=item sub packet_type()

 $value = $los_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Line of Sight Response 
packet. The value of this attribute must be 104.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $los_resp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $los_resp->request_ident($newValue);

LOS ID.

This attribute identifies the LOS response. This value corresponds to the value 
of the LOS ID attribute in the associated Line of Sight Segment Request packet 
or Line of Sight Vector Request packet.

=cut

sub request_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'requestIdent'} = $nv;
  }
  return $self->{'requestIdent'};
}

#==============================================================================

=item sub host_frame_number_lsn([$newValue])

 $value = $los_resp->host_frame_number_lsn($newValue);

Host Frame Number LSN.

This attribute contains the least significant nybble of the Host Frame Number 
attribute of the last IG Control packet received before the LOS data are 
calculated.
This attribute is ignored if the Update Period attribute of the corresponding 
Line of Sight Segment Request or Line of Sight Vector Request packet was set to 
zero (0).

=cut

sub host_frame_number_lsn() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'hostFrameNumberLSN'} = $nv;
    $self->{'_bitfields1'} |= ($nv << 4) &0xF0;
  }
  return (($self->{'_bitfields1'} & 0xF0) >> 4);
}

#==============================================================================

=item sub visible([$newValue])

 $value = $los_resp->visible($newValue);

Visible.

This attribute is used in response to a Line of Sight Segment Request packet. 
It indicates whether the destination point is visible from the source point.

This value should be ignored if the packet is in response to a Line of Sight 
Vector Request packet.

Note: If the LOS segment destination point is within the body of a target 
entity model, this attribute will be set to Occluded (0) and the Entity ID 
attribute will contain the ID of that entity.

    Occluded   0
    Visible    1

=cut

sub visible() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'visible'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "visible must be 0 (Occluded), or 1 (Visible).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub entity_ident_valid([$newValue])

 $value = $los_resp->entity_ident_valid($newValue);

Entity ID Valid.

This attribute indicates whether the LOS test vector or segment intersects with 
an entity (Valid) or a non-entity (Invalid).

    Invalid   0
    Valid     1

=cut

sub entity_ident_valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'entityIdentValid'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "entity_ident_valid must be 0 (Invalid), or 1 (Valid).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub valid([$newValue])

 $value = $los_resp->valid($newValue);

Valid.

This attribute indicates whether the Range attribute is valid. The range will 
be invalid if no intersection occurs, or if an intersection occurs before the 
minimum range or beyond the maximum range specified in a LOS vector request.

    Invalid   0
    Valid     1

=cut

sub valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'valid'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "valid must be 0 (Invalid), or 1 (Valid).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub response_count([$newValue])

 $value = $los_resp->response_count($newValue);

Response Count.

This attribute indicates the total number of Line of Sight Response packets the 
IG will return for the corresponding request.

Note: If Visible is set to Visible (1), then Response Count should be set to 1.

=cut

sub response_count() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'responseCount'} = $nv;
  }
  return $self->{'responseCount'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $los_resp->entity_ident($newValue);

Entity ID.

This attribute indicates the entity with which an LOS test vector or segment 
intersects. This attribute should be ignored if Entity ID Valid is set to 
Invalid (0).

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub range([$newValue])

 $value = $los_resp->range($newValue);

Range.

This attribute indicates the distance along the LOS test segment or vector from 
the source point to the point of intersection with a polygon surface.

=cut

sub range() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'range'} = $nv;
  }
  return $self->{'range'};
}

#==========================================================================

=item sub pack()

 $value = $los_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'_bitfields1'},    # Includes bitfields hostFrameNumberLSN, unused73, visible, entityIdentValid, and valid.
        $self->{'responseCount'},
        $self->{'entityIdent'},
        $self->{'range'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $los_resp->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;

  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'requestIdent'}                        = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields hostFrameNumberLSN, unused73, visible, entityIdentValid, and valid.
  $self->{'responseCount'}                       = $e;
  $self->{'entityIdent'}                         = $f;
  $self->{'range'}                               = $g;

  $self->{'hostFrameNumberLSN'}                  = $self->host_frame_number_lsn();
  $self->{'visible'}                             = $self->visible();
  $self->{'entityIdentValid'}                    = $self->entity_ident_valid();
  $self->{'valid'}                               = $self->valid();

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub byte_swap()

 $obj_name->byte_swap();

Byte swaps the packed data packet.

=cut

sub byte_swap($) {
  my $self = shift @_;

  if (@_) {
     $self->{'_Buffer'} = shift @_;
  } else {
     $self->pack();
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g);
  $self->unpack();

  return $self->{'_Buffer'};
}

1;
__END__

=head1 SEE ALSO

Refer the the Common Image Generator Interface ICD which may be had at this URL:
L<http://cigi.sourceforge.net/specification.php>

=head1 AUTHOR

Brian M. Ames, E<lt>bmames@apk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Brian M. Ames

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
