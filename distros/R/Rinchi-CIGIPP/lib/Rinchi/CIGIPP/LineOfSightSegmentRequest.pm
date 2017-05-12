#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78af5d8-200e-11de-bdb9-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::LineOfSightSegmentRequest;

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

Rinchi::CIGIPP::LineOfSightSegmentRequest - Perl extension for the Common Image 
Generator Interface - Line Of Sight Segment Request data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::LineOfSightSegmentRequest;
  my $loss_rqst = Rinchi::CIGIPP::LineOfSightSegmentRequest->new();

  $packet_type = $loss_rqst->packet_type();
  $packet_size = $loss_rqst->packet_size();
  $request_ident = $loss_rqst->request_ident(21900);
  $destination_entity_valid = $loss_rqst->destination_entity_valid(Rinchi::CIGIPP->Valid);
  $response_coordinate_system = $loss_rqst->response_coordinate_system(Rinchi::CIGIPP->GeodeticCS);
  $destination_point_coordinate_system = $loss_rqst->destination_point_coordinate_system(Rinchi::CIGIPP->GeodeticCS);
  $source_point_coordinate_system = $loss_rqst->source_point_coordinate_system(Rinchi::CIGIPP->EntityCS);
  $request_type = $loss_rqst->request_type(Rinchi::CIGIPP->BasicLOS);
  $alpha_threshold = $loss_rqst->alpha_threshold(109);
  $source_entity_ident = $loss_rqst->source_entity_ident(49099);
  $source_latitude = $loss_rqst->source_latitude(51.147);
  $source_xoffset = $loss_rqst->source_xoffset(62.907);
  $source_longitude = $loss_rqst->source_longitude(78.025);
  $source_yoffset = $loss_rqst->source_yoffset(54.82);
  $source_altitude = $loss_rqst->source_altitude(58.857);
  $source_zoffset = $loss_rqst->source_zoffset(29.08);
  $destination_latitude = $loss_rqst->destination_latitude(43.842);
  $destination_xoffset = $loss_rqst->destination_xoffset(75.381);
  $destination_longitude = $loss_rqst->destination_longitude(44.992);
  $destination_yoffset = $loss_rqst->destination_yoffset(15.47);
  $destination_altitude = $loss_rqst->destination_altitude(36.503);
  $destination_zoffset = $loss_rqst->destination_zoffset(16.844);
  $material_mask = $loss_rqst->material_mask(52904);
  $update_period = $loss_rqst->update_period(241);
  $destination_entity_ident = $loss_rqst->destination_entity_ident(60143);

=head1 DESCRIPTION

Line-of-Sight (LOS) Segment testing is used to determine whether an object lies 
along a test segment. This type of test is typically used to determine whether 
one point is visible from another, or whether the point is occluded by some 
object. The Line of Sight test segment is defined in the Line of Sight Segment 
Request packet by a source point and a destination point.

The LOS ID attribute is used to correlate requests from the Host with responses 
from the IG. When the IG responds to a LOS request, it will copy the LOS ID 
value contained within the request to the LOS ID attribute of the corresponding 
response packet.

Note that Line of Sight Segment Request packets and Line of Sight Vector 
Request packets share the LOS ID attribute. Duplicating the LOS ID value 
between both request types can cause data loss.

If the Request Type attribute is set to Basic (0), the IG will respond with a 
Line of Sight Response packet. If the attribute is set to Extended (1), the IG 
will respond with a Line of Sight Extended Response packet.

The Alpha Threshold attribute specifies the minimum alpha value with which an 
intersection should register. If an LOS test segment intersects with a surface 
whose alpha at the intersection point is lower than this value, no Line of 
Sight Response or Line of Sight Extended Response packet will be generated.

The Update Period attribute specifies the number of frames between periodic 
responses. This allows the Host to send just one Line of Sight Segment Request 
packet but receive continuous responses if the test point will not move with 
respect to the specified coordinate system. If Update Period is set to zero, 
the request will be treated as a one-shot request and the IG will return a 
single response. The Host should manipulate the value of LOS ID so that an ID 
is not reused before the IG has sufficient time to process and respond to the 
request. If Update Period is set to some value n greater than zero, the IG will 
return a request every nth frame until the Entity is destroyed or until the 
Update Period attribute set to zero.

The IG can only return valid LOS data if an intersection is detected along the 
LOS segment. If the LOS data cannot be calculated, the Valid attribute of the 
response packet will be set to zero (0).

The IG will generate a response for each intersection along the LOS segment. 

Besides the range of the LOS ID attribute, there is no restriction on the 
number of LOS requests that can be sent in a single frame; however, the 
response time of the IG might be degraded as the number of LOS requests increases.

=head2 EXPORT

None by default.

#==============================================================================

=item new $loss_rqst = Rinchi::CIGIPP::LineOfSightSegmentRequest->new()

Constructor for Rinchi::LineOfSightSegmentRequest.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78af5d8-200e-11de-bdb9-001c25551abc',
    '_Pack'                                => 'CCSCCSddddddICCS',
    '_Swap1'                               => 'CCvCCvVVVVVVVVVVVVVCCv',
    '_Swap2'                               => 'CCnCCnNNNNNNNNNNNNNCCn',
    'packetType'                           => 25,
    'packetSize'                           => 64,
    'requestIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused42, destinationEntityValid, responseCoordinateSystem, destinationPointCoordinateSystem, sourcePointCoordinateSystem, and requestType.
    'destinationEntityValid'               => 0,
    'responseCoordinateSystem'             => 0,
    'destinationPointCoordinateSystem'     => 0,
    'sourcePointCoordinateSystem'          => 0,
    'requestType'                          => 0,
    'alphaThreshold'                       => 0,
    'sourceEntityIdent'                    => 0,
    'sourceLatitude_xOffset'               => 0,
    'sourceLongitude_yOffset'              => 0,
    'sourceAltitude_zOffset'               => 0,
    'destinationLatitude_xOffset'          => 0,
    'destinationLongitude_yOffset'         => 0,
    'destinationAltitude_zOffset'          => 0,
    'materialMask'                         => 0,
    'updatePeriod'                         => 0,
    '_unused43'                            => 0,
    'destinationEntityIdent'               => 0,
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

 $value = $loss_rqst->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Line of Sight Segment Request 
packet. The value of this attribute must be 25.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $loss_rqst->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 64.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $loss_rqst->request_ident($newValue);

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

=item sub destination_entity_valid([$newValue])

 $value = $loss_rqst->destination_entity_valid($newValue);

Destination Entity ID Valid.

This attribute determines whether the Destination Entity ID attribute contains 
a valid entity ID.

If this flag is set to Valid (1) and Destination Point Coordinate System is set 
to Entity (1), then the destination endpoint will be defined with respect to 
the entity specified by Destination Entity ID.

If this flag is set to Not Valid (0), then the destination endpoint will be 
defined with respect to either the source entity (specified by Source Entity 
ID) or the Geodetic coordinate system as determined by the Destination Point 
Coordinate System attribute.

    NotValid   0
    Valid      1

=cut

sub destination_entity_valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'destinationEntityValid'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "destination_entity_valid must be 0 (NotValid), or 1 (Valid).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub response_coordinate_system([$newValue])

 $value = $loss_rqst->response_coordinate_system($newValue);

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
      $self->{'responseCoordinateSystem'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "response_coordinate_system must be 0 (GeodeticCS), or 1 (EntityCS).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub destination_point_coordinate_system([$newValue])

 $value = $loss_rqst->destination_point_coordinate_system($newValue);

Destination Point Coordinate System.

This attribute indicates the coordinate system relative to which the test 
segment destination endpoint is specified. If this attribute is set to Geodetic 
(0), then the endpoint is given by latitude, longitude, and altitude.

If this attribute is set to Entity (1) and Destination Entity ID Valid is set 
to Not Valid (0), then the endpoint is defined relative to the reference point 
of the entity specified by Source Entity ID.

If this attribute is set to Entity (1) and Destination Entity ID Valid is set 
to Valid (1), then the endpoint is defined relative to the reference point of 
the entity specified by Destination Entity ID.

    GeodeticCS   0
    EntityCS     1

=cut

sub destination_point_coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'destinationPointCoordinateSystem'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "destination_point_coordinate_system must be 0 (GeodeticCS), or 1 (EntityCS).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub source_point_coordinate_system([$newValue])

 $value = $loss_rqst->source_point_coordinate_system($newValue);

Source Point Coordinate System.

This attribute indicates the coordinate system relative to which the test 
segment source endpoint is specified.

If this attribute is set to Geodetic (0), then the endpoint is given by 
latitude, longitude, and altitude.

If this attribute is set to Entity (1), then the endpoint is defined relative 
to the reference point of the entity specified by Entity ID.

    GeodeticCS   0
    EntityCS     1

=cut

sub source_point_coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'sourcePointCoordinateSystem'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "source_point_coordinate_system must be 0 (GeodeticCS), or 1 (EntityCS).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub request_type([$newValue])

 $value = $loss_rqst->request_type($newValue);

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
      $self->{'requestType'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "request_type must be 0 (BasicLOS), or 1 (ExtendedLOS).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub alpha_threshold([$newValue])

 $value = $loss_rqst->alpha_threshold($newValue);

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

 $value = $loss_rqst->source_entity_ident($newValue);

Source Entity ID.

This attribute specifies the entity relative to which the test segment 
endpoints are defined. This attribute is ignored if Source Point Coordinate 
System and Destination Point Coordinate System are both set to Geodetic (0).

=cut

sub source_entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceEntityIdent'} = $nv;
  }
  return $self->{'sourceEntityIdent'};
}

#==============================================================================

=item sub source_latitude([$newValue])

 $value = $loss_rqst->source_latitude($newValue);

Source Latitude.

If Source Point Coordinate System is set to Geodetic (0), this attribute 
specifies the latitude of the source endpoint of the LOS test segment.

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

 $value = $loss_rqst->source_xoffset($newValue);

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

 $value = $loss_rqst->source_longitude($newValue);

Source Longitude.

If Source Point Coordinate System is set to Geodetic (0), this attribute 
specifies the longitude of the source endpoint of the LOS test segment.

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

 $value = $loss_rqst->source_yoffset($newValue);

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

 $value = $loss_rqst->source_altitude($newValue);

Source Altitude.

If Source Point Coordinate System is set to Geodetic (0), this attribute 
specifies the altitude of the source endpoint of the LOS test segment.

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

 $value = $loss_rqst->source_zoffset($newValue);

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

=item sub destination_latitude([$newValue])

 $value = $loss_rqst->destination_latitude($newValue);

Destination Latitude.

If Destination Point Coordinate System is set to Geodetic (0), this attribute 
specifies the latitude of the destination endpoint of the LOS test segment.

=cut

sub destination_latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'destinationLatitude_xOffset'} = $nv;
  }
  return $self->{'destinationLatitude_xOffset'};
}

#==============================================================================

=item sub destination_xoffset([$newValue])

 $value = $loss_rqst->destination_xoffset($newValue);

Destination X Offset.

If Destination Point Coordinate System is set to Entity (1), this attribute 
specifies the X offset of the destination endpoint of the LOS test segment. 
This offset may be relative to either the source entity or destination entity, 
depending upon the value of the Destination Entity ID Valid flag.

=cut

sub destination_xoffset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'destinationLatitude_xOffset'} = $nv;
  }
  return $self->{'destinationLatitude_xOffset'};
}

#==============================================================================

=item sub destination_longitude([$newValue])

 $value = $loss_rqst->destination_longitude($newValue);

Destination Longitude.

If Destination Point Coordinate System is set to Geodetic (0), this attribute 
specifies the longitude of the destination endpoint of the LOS test segment.

=cut

sub destination_longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'destinationLongitude_yOffset'} = $nv;
  }
  return $self->{'destinationLongitude_yOffset'};
}

#==============================================================================

=item sub destination_yoffset([$newValue])

 $value = $loss_rqst->destination_yoffset($newValue);

Destination Y Offset.

If Destination Point Coordinate System is set to Entity (1), this attribute 
specifies the Y offset of the destination endpoint of the LOS test segment. 
This offset may be relative to either the source entity or destination entity, 
depending upon the value of the Destination Entity ID Valid flag.

=cut

sub destination_yoffset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'destinationLongitude_yOffset'} = $nv;
  }
  return $self->{'destinationLongitude_yOffset'};
}

#==============================================================================

=item sub destination_altitude([$newValue])

 $value = $loss_rqst->destination_altitude($newValue);

Destination Altitude.     (Geodetic Coordinate System)    

If Destination Point Coordinate System is set to Geodetic (0), this attribute 
specifies the altitude of the destination endpoint of the LOS test segment.

=cut

sub destination_altitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'destinationAltitude_zOffset'} = $nv;
  }
  return $self->{'destinationAltitude_zOffset'};
}

#==============================================================================

=item sub destination_zoffset([$newValue])

 $value = $loss_rqst->destination_zoffset($newValue);

Destination Z Offset.

If Destination Point Coordinate System is set to Entity (1), this attribute 
specifies the Z offset of the destination endpoint of the LOS test segment. 
This offset may be relative to either the source entity or destination entity, 
depending upon the value of the Destination Entity ID Valid flag.

=cut

sub destination_zoffset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'destinationAltitude_zOffset'} = $nv;
  }
  return $self->{'destinationAltitude_zOffset'};
}

#==============================================================================

=item sub material_mask([$newValue])

 $value = $loss_rqst->material_mask($newValue);

Material Mask.

This attribute specifies the environmental and cultural features to be included 
in or excluded from consideration for LOS segment testing. Each bit represents 
a material code range; setting that bit to one (1) will cause the IG to 
register intersections with polygons whose material codes are within that 
range.
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

 $value = $loss_rqst->update_period($newValue);

Update Period.

This attribute specifies the interval between successive responses to this 
request. A value of zero  (0) indicates that the IG should return a single 
response. A value of n > 0 indicates that the IG should  return a response 
every nth frame.

=cut

sub update_period() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'updatePeriod'} = $nv;
  }
  return $self->{'updatePeriod'};
}

#==============================================================================

=item sub destination_entity_ident([$newValue])

 $value = $loss_rqst->destination_entity_ident($newValue);

Destination Entity ID.

This attribute indicates the entity with respect to which the Destination X 
Offset, Destination Y Offset, and Destination Z Offset attributes are 
specified.
This attribute is used only if the Destination Point Coordinate System 
attribute is set to Entity (1) and the Destination Entity ID Valid flag is set 
to Valid (1).

=cut

sub destination_entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'destinationEntityIdent'} = $nv;
  }
  return $self->{'destinationEntityIdent'};
}

#==========================================================================

=item sub pack()

 $value = $loss_rqst->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused42, destinationEntityValid, responseCoordinateSystem, destinationPointCoordinateSystem, sourcePointCoordinateSystem, and requestType.
        $self->{'alphaThreshold'},
        $self->{'sourceEntityIdent'},
        $self->{'sourceLatitude_xOffset'},
        $self->{'sourceLongitude_yOffset'},
        $self->{'sourceAltitude_zOffset'},
        $self->{'destinationLatitude_xOffset'},
        $self->{'destinationLongitude_yOffset'},
        $self->{'destinationAltitude_zOffset'},
        $self->{'materialMask'},
        $self->{'updatePeriod'},
        $self->{'_unused43'},
        $self->{'destinationEntityIdent'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $loss_rqst->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'requestIdent'}                        = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused42, destinationEntityValid, responseCoordinateSystem, destinationPointCoordinateSystem, sourcePointCoordinateSystem, and requestType.
  $self->{'alphaThreshold'}                      = $e;
  $self->{'sourceEntityIdent'}                   = $f;
  $self->{'sourceLatitude_xOffset'}              = $g;
  $self->{'sourceLongitude_yOffset'}             = $h;
  $self->{'sourceAltitude_zOffset'}              = $i;
  $self->{'destinationLatitude_xOffset'}         = $j;
  $self->{'destinationLongitude_yOffset'}        = $k;
  $self->{'destinationAltitude_zOffset'}         = $l;
  $self->{'materialMask'}                        = $m;
  $self->{'updatePeriod'}                        = $n;
  $self->{'_unused43'}                           = $o;
  $self->{'destinationEntityIdent'}              = $p;

  $self->{'destinationEntityValid'}              = $self->destination_entity_valid();
  $self->{'responseCoordinateSystem'}            = $self->response_coordinate_system();
  $self->{'destinationPointCoordinateSystem'}    = $self->destination_point_coordinate_system();
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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s,$t,$u,$v) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g,$j,$i,$l,$k,$n,$m,$p,$o,$r,$q,$s,$t,$u,$v);
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
