#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78af880-200e-11de-bdba-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::LineOfSightVectorRequest;

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

Rinchi::CIGIPP::LineOfSightVectorRequest - Perl extension for the Common Image 
Generator Interface - Line Of Sight Vector Request data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::LineOfSightVectorRequest;
  my $losv_rqst = Rinchi::CIGIPP::LineOfSightVectorRequest->new();

  $packet_type = $losv_rqst->packet_type();
  $packet_size = $losv_rqst->packet_size();
  $request_ident = $losv_rqst->request_ident(38090);
  $response_coordinate_system = $losv_rqst->response_coordinate_system(Rinchi::CIGIPP->EntityCS);
  $source_point_coordinate_system = $losv_rqst->source_point_coordinate_system(Rinchi::CIGIPP->GeodeticCS);
  $request_type = $losv_rqst->request_type(Rinchi::CIGIPP->BasicLOS);
  $alpha_threshold = $losv_rqst->alpha_threshold(186);
  $source_entity_ident = $losv_rqst->source_entity_ident(37849);
  $azimuth = $losv_rqst->azimuth(41.692);
  $elevation = $losv_rqst->elevation(53.069);
  $minimum_range = $losv_rqst->minimum_range(8.405);
  $maximum_range = $losv_rqst->maximum_range(66.277);
  $source_latitude = $losv_rqst->source_latitude(54.95);
  $source_xoffset = $losv_rqst->source_xoffset(47.242);
  $source_longitude = $losv_rqst->source_longitude(63.473);
  $source_yoffset = $losv_rqst->source_yoffset(13.438);
  $source_altitude = $losv_rqst->source_altitude(52.653);
  $source_zoffset = $losv_rqst->source_zoffset(14.289);
  $material_mask = $losv_rqst->material_mask(37559);
  $update_period = $losv_rqst->update_period(103);

=head1 DESCRIPTION

Line-of-Sight (LOS) Vector testing is used to determine the range from a source 
point to an object along a test vector. Applications may include but are not 
limited to laser range finding, determining range to target, and testing for 
weight on wheels. The Line of Sight test vector emanates from the source 
position specified in the Line of Sight Vector Request packet. A minimum and a 
maximum range are specified in order to constrain the search.

The LOS ID attribute is used to correlate requests from the Host with responses 
from the IG. When the IG responds to a LOS request, it will copy the LOS ID 
value contained within the request to the LOS ID attribute of the corresponding 
response packet. The Host should manipulate the value of LOS ID so that the ID 
is not reused before the IG has sufficient time to respond to the LOS request. 
This will prevent similarly identified requests from being lost by the IG.

Note that Line of Sight Segment Request packets and Line of Sight Vector 
Request packets share the LOS ID attribute. Duplicating the LOS ID value 
between both request types can also cause data loss.

If the Request Type attribute is set to Basic (0), the IG will respond with a 
Line of Sight Response packet. If the attribute is set to Extended (1), the IG 
will respond with a Line of Sight Extended Response packet.

The Alpha Threshold attribute specifies the minimum alpha value with which an 
intersection should register. If an LOS test vector intersects with a surface 
whose alpha at the intersection point is lower than this value, no Line of 
Sight Response or Line of Sight Extended Response packet will be generated.

The Update Period attribute specifies the number of frames between periodic 
responses. This allows the Host to send just one Line of Sight Vector Request 
packet but receive continuous responses if the test point will not move with 
respect to the specified coordinate system. If Update Period is set to zero, 
the request will be treated as a one-shot request and the IG will return a 
single response. The Host should manipulate the value of LOS ID so that an ID 
is not reused before the IG has sufficient time to process and respond to the 
request. If Update Period is set to some value n greater than zero, the IG will 
return a request every nth frame until the Entity is destroyed or until the 
Update Period attribute set to zero.

The IG can only return valid LOS data if an intersection is detected along the 
LOS segment, that is, between the minimum and maximum ranges specified. If the 
LOS data cannot be calculated, the Valid attribute of the response packet will 
be set to zero (0).

The IG will generate a response for each intersection along the LOS vector.

Besides the range of the LOS ID attribute, there is no restriction on the 
number of LOS requests that can be sent in a single frame; however, the 
response time of the IG might be degraded as the number of LOS requests increases.

=head2 EXPORT

None by default.

#==============================================================================

=item new $losv_rqst = Rinchi::CIGIPP::LineOfSightVectorRequest->new()

Constructor for Rinchi::LineOfSightVectorRequest.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78af880-200e-11de-bdba-001c25551abc',
    '_Pack'                                => 'CCSCCSffffdddICCS',
    '_Swap1'                               => 'CCvCCvVVVVVVVVVVVCCv',
    '_Swap2'                               => 'CCnCCnNNNNNNNNNNNCCn',
    'packetType'                           => 26,
    'packetSize'                           => 56,
    'requestIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused44, responseCoordinateSystem, sourcePointCoordinateSystem, and requestType.
    'responseCoordinateSystem'             => 0,
    'sourcePointCoordinateSystem'          => 0,
    'requestType'                          => 0,
    'alphaThreshold'                       => 0,
    'sourceEntityIdent'                    => 0,
    'azimuth'                              => 0,
    'elevation'                            => 0,
    'minimumRange'                         => 0,
    'maximumRange'                         => 0,
    'sourceLatitude_xOffset'               => 0,
    'sourceLongitude_yOffset'              => 0,
    'sourceAltitude_zOffset'               => 0,
    'materialMask'                         => 0,
    'updatePeriod'                         => 0,
    '_unused45'                            => 0,
    '_unused46'                            => 0,
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

 $value = $losv_rqst->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Line of Sight Vector Request 
packet. The value of this attribute must be 26.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $losv_rqst->packet_size();

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

 $value = $losv_rqst->request_ident($newValue);

LOS ID.

This attribute identifies the LOS request. When the IG returns a Line of Sight 
Response packet in response to this request, the LOS ID attribute of that 
packet will contain this value to correlate the response with this request.

Note: Because the Line of Sight Response data packet is used for responding to 
both the LOS segment and LOS vector requests, the LOS ID value used for one 
request type should not be duplicated for the other request type before the IG 
has sufficient time to generate a response.

=cut

sub request_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'requestIdent'} = $nv;
  }
  return $self->{'requestIdent'};
}

#==============================================================================

=item sub response_coordinate_system([$newValue])

 $value = $losv_rqst->response_coordinate_system($newValue);

Response Coordinate System.

This attribute specifies the coordinate system to be used in the response.

If this attribute is set to Geodetic (0), then the intersection point will be 
specified by latitude, longitude, and altitude.

If this attribute is set to Entity (1), then the intersection point will be 
specified relative to the reference point of the intersected entity.

    GeodeticCS   0
    EntityCS     1

=cut

sub response_coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "response_coordinate_system must be 0 (GeodeticCS), or 1 (EntityCS).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub source_point_coordinate_system([$newValue])

 $value = $losv_rqst->source_point_coordinate_system($newValue);

Source Point Coordinate System.

This attribute indicates the coordinate system relative to which the test 
vector source point is specified.

If this attribute is set to Geodetic (0), then the point is given by latitude, 
longitude, and altitude. The vector, specified by Azimuth and Elevation, is 
defined relative to the Geodetic coordinate system.

If this attribute is set to Entity (1), then the point is defined relative to 
the reference point of the entity specified by Entity ID. The vector is also 
specified relative to the entity's coordinate system.

    GeodeticCS   0
    EntityCS     1

=cut

sub source_point_coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "source_point_coordinate_system must be 0 (GeodeticCS), or 1 (EntityCS).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub request_type([$newValue])

 $value = $losv_rqst->request_type($newValue);

Request Type.

This attribute determines what type of response the IG should return for this 
request.
If this attribute is set to Basic (0), the IG will respond with a Line of Sight 
Response packet. If this attribute is set to Extended (1), the IG will respond 
with a Line of Sight Extended Response packet.

    BasicLOS      0
    ExtendedLOS   1

=cut

sub request_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "request_type must be 0 (BasicLOS), or 1 (ExtendedLOS).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub alpha_threshold([$newValue])

 $value = $losv_rqst->alpha_threshold($newValue);

Alpha Threshold.

This attribute specifies the minimum alpha value (i.e., minimum opacity) a 
surface may have for an LOS response to be generated.

=cut

sub alpha_threshold() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'alphaThreshold'} = $nv;
  }
  return $self->{'alphaThreshold'};
}

#==============================================================================

=item sub source_entity_ident([$newValue])

 $value = $losv_rqst->source_entity_ident($newValue);

Entity ID.

This attribute specifies the entity relative to which the test segment 
endpoints are defined. This attribute is ignored if Source Point Coordinate 
System is set to Geodetic (0).

=cut

sub source_entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceEntityIdent'} = $nv;
  }
  return $self->{'sourceEntityIdent'};
}

#==============================================================================

=item sub azimuth([$newValue])

 $value = $losv_rqst->azimuth($newValue);

Azimuth.

This attribute specifies the horizontal angle of the LOS test vector.

=cut

sub azimuth() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'azimuth'} = $nv;
  }
  return $self->{'azimuth'};
}

#==============================================================================

=item sub elevation([$newValue])

 $value = $losv_rqst->elevation($newValue);

Elevation.

This attribute specifies the vertical angle of the LOS test vector.

=cut

sub elevation() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'elevation'} = $nv;
  }
  return $self->{'elevation'};
}

#==============================================================================

=item sub minimum_range([$newValue])

 $value = $losv_rqst->minimum_range($newValue);

Minimum Range.

This attribute specifies the minimum range along the LOS test vector at which 
intersection testing should occur.

=cut

sub minimum_range() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'minimumRange'} = $nv;
  }
  return $self->{'minimumRange'};
}

#==============================================================================

=item sub maximum_range([$newValue])

 $value = $losv_rqst->maximum_range($newValue);

Maximum Range.

This attribute specifies the maximum range along the LOS test vector at which 
intersection testing should occur.

=cut

sub maximum_range() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'maximumRange'} = $nv;
  }
  return $self->{'maximumRange'};
}

#==============================================================================

=item sub source_latitude([$newValue])

 $value = $losv_rqst->source_latitude($newValue);

Source Latitude.   

If Source point Coordinate System is set to Geodetic (0), this attribute 
specifies the latitude of the source point of the LOS test vector.

=cut

sub source_latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceLatitude_xOffset'} = $nv;
  }
  return $self->{'sourceLatitude_xOffset'};
}

#==============================================================================

=item sub source_xoffset([$newValue])

 $value = $losv_rqst->source_xoffset($newValue);

Source X Offset.

If Source Point Coordinate System is set to Entity (1), this attribute 
specifies the X offset of the source endpoint of the LOS test segment.

=cut

sub source_xoffset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceLatitude_xOffset'} = $nv;
  }
  return $self->{'sourceLatitude_xOffset'};
}

#==============================================================================

=item sub source_longitude([$newValue])

 $value = $losv_rqst->source_longitude($newValue);

Source Longitude.

If Source point Coordinate System is set to Geodetic (0), this attribute 
specifies the longitude of the source point of the LOS test vector.

=cut

sub source_longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceLongitude_yOffset'} = $nv;
  }
  return $self->{'sourceLongitude_yOffset'};
}

#==============================================================================

=item sub source_yoffset([$newValue])

 $value = $losv_rqst->source_yoffset($newValue);

Source Y Offset.

If Source Point Coordinate System is set to Entity (1), this attribute 
specifies the Y offset of the source endpoint of the LOS test segment.

=cut

sub source_yoffset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceLongitude_yOffset'} = $nv;
  }
  return $self->{'sourceLongitude_yOffset'};
}

#==============================================================================

=item sub source_altitude([$newValue])

 $value = $losv_rqst->source_altitude($newValue);

Source Altitude.

If Source Point Coordinate System is set to Geodetic (0), this attribute 
specifies the altitude of the source point of the LOS test vector.

=cut

sub source_altitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceAltitude_zOffset'} = $nv;
  }
  return $self->{'sourceAltitude_zOffset'};
}

#==============================================================================

=item sub source_zoffset([$newValue])

 $value = $losv_rqst->source_zoffset($newValue);

Source Z Offset.      

If Source Point Coordinate System is set to Entity (1), this attribute 
specifies the Z offset of the source endpoint of the LOS test segment.

=cut

sub source_zoffset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceAltitude_zOffset'} = $nv;
  }
  return $self->{'sourceAltitude_zOffset'};
}

#==============================================================================

=item sub material_mask([$newValue])

 $value = $losv_rqst->material_mask($newValue);

Material Mask.

This attribute specifies the environmental and cultural features to be included 
in LOS segment testing. Each bit represents a material code range; setting that 
bit to one (1) will cause the IG to register intersections with polygons whose 
material codes are within that range.

Material code ranges are IG-dependent. Refer to the appropriate IG 
documentation for material code assignments.

=cut

sub material_mask() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'materialMask'} = $nv;
  }
  return $self->{'materialMask'};
}

#==============================================================================

=item sub update_period([$newValue])

 $value = $losv_rqst->update_period($newValue);

Update Period.

This attribute specifies the interval between successive responses to this 
request. A value of zero (0) indicates that the IG should return a single 
response. A value of n > 0 indicates that the IG should return a response every 
nth frame.

=cut

sub update_period() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'updatePeriod'} = $nv;
  }
  return $self->{'updatePeriod'};
}

#==========================================================================

=item sub pack()

 $value = $losv_rqst->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused44, responseCoordinateSystem, sourcePointCoordinateSystem, and requestType.
        $self->{'alphaThreshold'},
        $self->{'sourceEntityIdent'},
        $self->{'azimuth'},
        $self->{'elevation'},
        $self->{'minimumRange'},
        $self->{'maximumRange'},
        $self->{'sourceLatitude_xOffset'},
        $self->{'sourceLongitude_yOffset'},
        $self->{'sourceAltitude_zOffset'},
        $self->{'materialMask'},
        $self->{'updatePeriod'},
        $self->{'_unused45'},
        $self->{'_unused46'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $losv_rqst->unpack();

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
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused44, responseCoordinateSystem, sourcePointCoordinateSystem, and requestType.
  $self->{'alphaThreshold'}                      = $e;
  $self->{'sourceEntityIdent'}                   = $f;
  $self->{'azimuth'}                             = $g;
  $self->{'elevation'}                           = $h;
  $self->{'minimumRange'}                        = $i;
  $self->{'maximumRange'}                        = $j;
  $self->{'sourceLatitude_xOffset'}              = $k;
  $self->{'sourceLongitude_yOffset'}             = $l;
  $self->{'sourceAltitude_zOffset'}              = $m;
  $self->{'materialMask'}                        = $n;
  $self->{'updatePeriod'}                        = $o;
  $self->{'_unused45'}                           = $p;
  $self->{'_unused46'}                           = $q;

  $self->{'responseCoordinateSystem'}            = $self->response_coordinate_system();
  $self->{'sourcePointCoordinateSystem'}         = $self->source_point_coordinate_system();
  $self->{'requestType'}                         = $self->request_type();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s,$t) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$l,$k,$n,$m,$p,$o,$q,$r,$s,$t);
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
