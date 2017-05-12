#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b2364-200e-11de-bdca-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::LineOfSightExtendedResponse;

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

our $VERSION = '0.02';

# Preloaded methods go here.

=head1 NAME

Rinchi::CIGIPP::LineOfSightExtendedResponse - Perl extension for the Common 
Image Generator Interface - Line Of Sight Extended Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::LineOfSightExtendedResponse;
  my $los_xresp = Rinchi::CIGIPP::LineOfSightExtendedResponse->new();

  $packet_type = $los_xresp->packet_type();
  $packet_size = $los_xresp->packet_size();
  $request_ident = $los_xresp->request_ident(57);
  $host_frame_number_lsn = $los_xresp->host_frame_number_lsn(4);
  $visible = $los_xresp->visible(Rinchi::CIGIPP->Occluded);
  $range_valid = $los_xresp->range_valid(Rinchi::CIGIPP->Invalid);
  $entity_ident_valid = $los_xresp->entity_ident_valid(Rinchi::CIGIPP->Invalid);
  $valid = $los_xresp->valid(Rinchi::CIGIPP->Valid);
  $response_count = $los_xresp->response_count(217);
  $entity_ident = $los_xresp->entity_ident(41000);
  $range = $los_xresp->range(17.74);
  $latitude = $los_xresp->latitude(19.293);
  $x_offset = $los_xresp->x_offset(14.649);
  $longitude = $los_xresp->longitude(57.589);
  $y_offset = $los_xresp->y_offset(47.628);
  $altitude = $los_xresp->altitude(9.33);
  $z_offset = $los_xresp->z_offset(43.407);
  $red = $los_xresp->red(89);
  $green = $los_xresp->green(122);
  $blue = $los_xresp->blue(160);
  $alpha = $los_xresp->alpha(242);
  $material_code = $los_xresp->material_code(22573);
  $normal_vector_azimuth = $los_xresp->normal_vector_azimuth(35.653);
  $normal_vector_elevation = $los_xresp->normal_vector_elevation(41.678);

=head1 DESCRIPTION

The Line of Sight Extended Response packet is used in response to both Line of 
Sight Segment Request and Line of Sight Vector Request packets. This packet 
contains positional data describing the Line of Sight (LOS) intersection point. 
In addition, it contains the material code and surface-normal unit vector of 
the polygon at the point of intersection. The packet is sent when the Request 
Type attribute of the request packet is set to Extended (1).

A Line of Sight Extended Response packet will be sent for each intersection 
along the LOS segment or vector. The Response Count attribute will contain the 
total number of responses that are being returned. This will allow the Host to 
determine when all response packets for the given request have been received.

For responses to Line of Sight Segment Request packets, the Range, Altitude, 
Latitude, and Longitude attributes specify the range to and position of the 
intersection point along the LOS test segment. If the destination point 
specified in the request is occulted, these attributes specify the range to and 
position of a point on the surface occulting the destination. If the 
destination point is not occluded, these attributes simply provide the range to 
and position of the destination point. 

For responses to Line of Sight Vector Request packets, the Range, Altitude, 
Latitude, and Longitude attributes specify the range to and position of the 
point of intersection between the test vector and a surface. If no intersection 
occurs within the valid range specified in the request, the Valid attribute is 
set to Invalid (0).

=head2 EXPORT

None by default.

#==============================================================================

=item new $los_xresp = Rinchi::CIGIPP::LineOfSightExtendedResponse->new()

Constructor for Rinchi::LineOfSightExtendedResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b2364-200e-11de-bdca-001c25551abc',
    '_Pack'                                => 'CCSCCSddddCCCCIff',
    '_Swap1'                               => 'CCvCCvVVVVVVVVCCCCVVV',
    '_Swap2'                               => 'CCnCCnNNNNNNNNCCCCNNN',
    'packetType'                           => 105,
    'packetSize'                           => 56,
    'requestIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields hostFrameNumberLSN, visible, rangeValid, entityIdentValid, and valid.
    'hostFrameNumberLSN'                   => 0,
    'visible'                              => 0,
    'rangeValid'                           => 0,
    'entityIdentValid'                     => 0,
    'valid'                                => 0,
    'responseCount'                        => 0,
    'entityIdent'                          => 0,
    'range'                                => 0,
    'latitude_xOffset'                     => 0,
    'longitude_yOffset'                    => 0,
    'altitude_zOffset'                     => 0,
    'red'                                  => 0,
    'green'                                => 0,
    'blue'                                 => 0,
    'alpha'                                => 0,
    'materialCode'                         => 0,
    'normalVectorAzimuth'                  => 0,
    'normalVectorElevation'                => 0,
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

 $value = $los_xresp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Line of Sight Extended 
Response packet. The value of this attribute must be 105.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $los_xresp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 56.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $los_xresp->request_ident($newValue);

LOS ID.

This attribute corresponds to the value of the LOS ID attribute in the 
associated Line of Sight Segment Request or Line of Sight Vector Request packet.

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

 $value = $los_xresp->host_frame_number_lsn($newValue);

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

 $value = $los_xresp->visible($newValue);

Visible.

This attribute is used in response to a Line of Sight Segment Request packet 
and indicates whether the destination point is visible from the source point. 
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
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "visible must be 0 (Occluded), or 1 (Visible).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub range_valid([$newValue])

 $value = $los_xresp->range_valid($newValue);

Range Valid.

This attribute indicates whether the Range attribute is valid. The range will 
be invalid if an intersection occurs before the minimum range or beyond the 
maximum range specified in an LOS vector request. The range will also be 
invalid if this packet is in response to an LOS segment request.

If Valid is set to Invalid (0), this attribute will also be set to Invalid (0).

    Invalid   0
    Valid     1

=cut

sub range_valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'rangeValid'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "range_valid must be 0 (Invalid), or 1 (Valid).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub entity_ident_valid([$newValue])

 $value = $los_xresp->entity_ident_valid($newValue);

Entity Ident Valid.

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

 $value = $los_xresp->valid($newValue);

Valid.

This attribute indicates whether this packet contains valid data. A value of 
Invalid (0) indicates that the LOS test segment or vector did not intersect any geometry.

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

 $value = $los_xresp->response_count($newValue);

Response Count.

This attribute indicates the total number of Line of Sight Extended Response 
packets the IG will return for the corresponding request.

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

 $value = $los_xresp->entity_ident($newValue);

Entity Identifier.

This attribute indicates the entity with which a LOS test vector or segment 
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

 $value = $los_xresp->range($newValue);

Range.

This attribute represents the distance along the LOS test segment or vector 
from the source point to the point of intersection with a polygon surface.

=cut

sub range() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'range'} = $nv;
  }
  return $self->{'range'};
}

#==============================================================================

=item sub latitude([$newValue])

 $value = $los_xresp->latitude($newValue);

Latitude.

If the Entity ID Valid attribute is set to Invalid (0) or if Response 
Coordinate System in the request packet was set to Geodetic (0), this attribute 
indicates the geodetic latitude of the point of intersection along the LOS test 
segment or vector.

If this packet is in response to an LOS segment request and Visible is set to 
Occluded (0), this point is on the  occulting surface. If this packet is in 
response to an LOS segment request and Visible is set to Visible (1), this 
point is simply the destination point.

=cut

sub latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'latitude_xOffset'} = $nv;
  }
  return $self->{'latitude_xOffset'};
}

#==============================================================================

=item sub x_offset([$newValue])

 $value = $los_xresp->x_offset($newValue);

X Offset.

If the Entity ID Valid attribute is set to Valid (1) and Response Coordinate 
System in the request packet was set to Entity (1), this attribute specifies 
the offset of the point of intersection of the LOS test segment or vector along 
the intersected entity's X axis.

=cut

sub x_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'latitude_xOffset'} = $nv;
  }
  return $self->{'latitude_xOffset'};
}

#==============================================================================

=item sub longitude([$newValue])

 $value = $los_xresp->longitude($newValue);

Longitude.

If the Entity ID Valid attribute is set to Invalid (0) or if Response 
Coordinate System in the request packet was set to Geodetic (0), this attribute 
indicates the geodetic longitude of the point of intersection along the LOS 
test segment or vector.

If this packet is in response to an LOS segment request and Visible is set to 
Occluded (0), this point is on the occulting surface. If this packet is in 
response to an LOS segment request and Visible is set to Visible (1), this 
point is simply the destination point.

=cut

sub longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'longitude_yOffset'} = $nv;
  }
  return $self->{'longitude_yOffset'};
}

#==============================================================================

=item sub y_offset([$newValue])

 $value = $los_xresp->y_offset($newValue);

Y Offset.

If the Entity ID Valid attribute is set to Valid (1) and Response Coordinate 
System in the request packet was set to Entity (1), this attribute specifies 
the offset of the point of intersection of the LOS test segment or vector along 
the intersected entity's Y axis.

=cut

sub y_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'longitude_yOffset'} = $nv;
  }
  return $self->{'longitude_yOffset'};
}

#==============================================================================

=item sub altitude([$newValue])

 $value = $los_xresp->altitude($newValue);

Altitude.

If the Entity ID Valid attribute is set to Invalid (0) or if Response 
Coordinate System in the request packet was set to Geodetic (0), this attribute 
indicates the geodetic altitude of the point of intersection along the LOS test 
segment or vector.

If this packet is in response to a LOS segment request and Visible is set to 
Occluded (0), this point is on the occulting surface. If this packet is in 
response to a LOS segment request and Visible is set to Visible (1), this point 
is simply the destination point.

=cut

sub altitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'altitude_zOffset'} = $nv;
  }
  return $self->{'altitude_zOffset'};
}

#==============================================================================

=item sub z_offset([$newValue])

 $value = $los_xresp->z_offset($newValue);

Z Offset.

If the Entity ID Valid attribute is set to Valid (1) and Response Coordinate 
System in the request packet was set to Entity (1), this attribute specifies 
the offset of the point of intersection of the LOS test segment or vector along 
the intersected entity's Z axis.

=cut

sub z_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'altitude_zOffset'} = $nv;
  }
  return $self->{'altitude_zOffset'};
}

#==============================================================================

=item sub red([$newValue])

 $value = $los_xresp->red($newValue);

Red.

This attribute indicates the red color component of the surface at the point of intersection.

=cut

sub red() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'red'} = $nv;
  }
  return $self->{'red'};
}

#==============================================================================

=item sub green([$newValue])

 $value = $los_xresp->green($newValue);

Green.

This attribute indicates the green color component of the surface at the point 
of intersection.

=cut

sub green() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'green'} = $nv;
  }
  return $self->{'green'};
}

#==============================================================================

=item sub blue([$newValue])

 $value = $los_xresp->blue($newValue);

Blue.

This attribute indicates the blue color component of the surface at the point 
of intersection.

=cut

sub blue() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'blue'} = $nv;
  }
  return $self->{'blue'};
}

#==============================================================================

=item sub alpha([$newValue])

 $value = $los_xresp->alpha($newValue);

Alpha.

This attribute indicates the alpha color component of the surface at the point 
of intersection.

=cut

sub alpha() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'alpha'} = $nv;
  }
  return $self->{'alpha'};
}

#==============================================================================

=item sub material_code([$newValue])

 $value = $los_xresp->material_code($newValue);

Material Code.

This attribute indicates the material code of the surface intersected by the 
LOS test segment or vector.

=cut

sub material_code() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'materialCode'} = $nv;
  }
  return $self->{'materialCode'};
}

#==============================================================================

=item sub normal_vector_azimuth([$newValue])

 $value = $los_xresp->normal_vector_azimuth($newValue);

Normal Vector Azimuth.

This attribute represents the azimuth of the normal unit vector of the surface 
intersected by the HAT/HOT test vector. This value is the horizontal angle from 
True North to the vector.

=cut

sub normal_vector_azimuth() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'normalVectorAzimuth'} = $nv;
  }
  return $self->{'normalVectorAzimuth'};
}

#==============================================================================

=item sub normal_vector_elevation([$newValue])

 $value = $los_xresp->normal_vector_elevation($newValue);

Normal Vector Elevation.

This attribute represents the elevation of the normal unit vector of the 
surface intersected by the HAT/HOT test vector. This value is the vertical 
angle from the geodetic reference plane to the vector.

=cut

sub normal_vector_elevation() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'normalVectorElevation'} = $nv;
  }
  return $self->{'normalVectorElevation'};
}

#==========================================================================

=item sub pack()

 $value = $los_xresp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;

  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'_bitfields1'},    # Includes bitfields hostFrameNumberLSN, visible, rangeValid, entityIdentValid, and valid.
        $self->{'responseCount'},
        $self->{'entityIdent'},
        $self->{'range'},
        $self->{'latitude_xOffset'},
        $self->{'longitude_yOffset'},
        $self->{'altitude_zOffset'},
        $self->{'red'},
        $self->{'green'},
        $self->{'blue'},
        $self->{'alpha'},
        $self->{'materialCode'},
        $self->{'normalVectorAzimuth'},
        $self->{'normalVectorElevation'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $los_xresp->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;

  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'requestIdent'}                        = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields hostFrameNumberLSN, visible, rangeValid, entityIdentValid, and valid.
  $self->{'responseCount'}                       = $e;
  $self->{'entityIdent'}                         = $f;
  $self->{'range'}                               = $g;
  $self->{'latitude_xOffset'}                    = $h;
  $self->{'longitude_yOffset'}                   = $i;
  $self->{'altitude_zOffset'}                    = $j;
  $self->{'red'}                                 = $k;
  $self->{'green'}                               = $l;
  $self->{'blue'}                                = $m;
  $self->{'alpha'}                               = $n;
  $self->{'materialCode'}                        = $o;
  $self->{'normalVectorAzimuth'}                 = $p;
  $self->{'normalVectorElevation'}               = $q;

  $self->{'hostFrameNumberLSN'}                  = $self->host_frame_number_lsn();
  $self->{'visible'}                             = $self->visible();
  $self->{'rangeValid'}                          = $self->range_valid();
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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s,$t,$u) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g,$j,$i,$l,$k,$n,$m,$o,$p,$q,$r,$s,$t,$u);
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
