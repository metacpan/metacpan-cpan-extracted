#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78af2ae-200e-11de-bdb8-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::HAT_HOTRequest;

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

Rinchi::CIGIPP::HAT_HOTRequest - Perl extension for the Common Image Generator 
Interface - HAT/HOTRequest data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::HAT_HOTRequest;
  my $hgt_rqst = Rinchi::CIGIPP::HAT_HOTRequest->new();

  $packet_type = $hgt_rqst->packet_type();
  $packet_size = $hgt_rqst->packet_size();
  $request_ident = $hgt_rqst->request_ident(13384);
  $coordinate_system = $hgt_rqst->coordinate_system(Rinchi::CIGIPP->GeodeticCS);
  $request_type = $hgt_rqst->request_type(Rinchi::CIGIPP->HeightOfTerrain);
  $update_period = $hgt_rqst->update_period(156);
  $entity_ident = $hgt_rqst->entity_ident(48093);
  $latitude = $hgt_rqst->latitude(69.592);
  $x_offset = $hgt_rqst->x_offset(17.607);
  $longitude = $hgt_rqst->longitude(68.523);
  $y_offset = $hgt_rqst->y_offset(20.113);
  $altitude = $hgt_rqst->altitude(43.044);
  $z_offset = $hgt_rqst->z_offset(23.044);

=head1 DESCRIPTION

The HAT/HOT Request packet is used by the Host to request the Height Above 
Terrain (HAT) of a specified point and/or the Height Of Terrain (HOT) below a 
specified test point. The test point may be defined with respect to either the 
Geodetic coordinate system or an entity's body coordinate system.

Each request is identified by the HAT/HOT ID attribute. When the IG responds to 
the request, it will set the HAT/HOT ID attribute of the response packet to 
match that in the request.

The Update Period attribute specifies the number of frames between periodic 
responses. This allows the Host to send just one HAT/HOT Request packet but 
receive continuous responses if the test point will not move with respect to 
the specified coordinate system. If Update Period is set to zero, the request 
will be treated as a one- shot request and the IG will return a single 
response. The Host should manipulate the value of HAT/HOT ID so that an ID is 
not reused before the IG has sufficient time to process and respond to the 
request. If Update Period is set to some value n greater than zero, the IG will 
return a request every nth frame until the Entity is destroyed or until the 
Update Period attribute set to zero.

If the Request Type attribute is set to HAT (0) or HOT (1), the IG will respond 
with a HAT/HOT Response packet (Section 4.2.2) containing the requested datum. 
If the attribute is set to Extended HAT/HOT (2), the IG will respond with a 
HAT/HOT Extended Response packet (Section 4.2.3) containing both data, along 
with the surface material code and normal vector.

The IG can only return valid HAT and/or HOT data if the test point is located 
within the bounds of the current database. If the HAT or HOT cannot be 
calculated, the Valid attribute of the response packet will be set to Invalid 
(0).
Besides the range of the HAT/HOT ID attribute, there is no restriction on the 
number of HAT and/or HOT requests that can be sent in a single frame; however, 
the response time of the IG might be degraded as the number of requests increases.

=head2 EXPORT

None by default.

#==============================================================================

=item new $hgt_rqst = Rinchi::CIGIPP::HAT_HOTRequest->new()

Constructor for Rinchi::HAT_HOTRequest.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78af2ae-200e-11de-bdb8-001c25551abc',
    '_Pack'                                => 'CCSCCSddd',
    '_Swap1'                               => 'CCvCCvVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNN',
    'packetType'                           => 24,
    'packetSize'                           => 32,
    'requestIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused41, coordinateSystem, and requestType.
    'coordinateSystem'                     => 0,
    'requestType'                          => 0,
    'updatePeriod'                         => 0,
    'entityIdent'                          => 0,
    'latitude_xOffset'                     => 0,
    'longitude_yOffset'                    => 0,
    'altitude_zOffset'                     => 0,
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

 $value = $hgt_rqst->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the HAT/HOT Request packet. The 
value of this attribute must be 24.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $hgt_rqst->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $hgt_rqst->request_ident($newValue);

HAT/HOT ID.

This attribute identifies the HAT/HOT request. When the IG returns a HAT/HOT 
Response or HAT/HOT Extended Response packet in response to this request, the 
HAT/HOT ID attribute of that packet will contain this value to correlate the 
response with this request.

=cut

sub request_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'requestIdent'} = $nv;
  }

  return $self->{'requestIdent'};
}

#==============================================================================

=item sub coordinate_system([$newValue])

 $value = $hgt_rqst->coordinate_system($newValue);

Coordinate System.

This attribute specifies the coordinate system within which the test point is 
defined.
If this attribute is set to Geodetic (0), the test point is defined as a 
Latitude, Longitude, and Altitude. If this attribute is set to Entity (1), the 
test point is defined as X, Y, and Z offsets from the reference point of the 
entity specified by Entity ID.

    GeodeticCS   0
    EntityCS     1

=cut

sub coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'coordinateSystem'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "coordinate_system must be 0 (GeodeticCS), or 1 (EntityCS).";
    }
  }

  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub request_type([$newValue])

 $value = $hgt_rqst->request_type($newValue);

Request Type.

This attribute determines what type of response packet the IG should return for 
this request.

If this attribute is set to HAT (0), the IG will respond with a HAT/HOT 
Response packet containing the Height Above Terrain. If this attribute is set 
to HOT (1), the IG will respond with a HAT/HOT Response  packet containing the 
Height Of Terrain. If this attribute is set to Extended (2), the IG will 
respond with a HAT/HOT Extended Response packet, which contains both the Height 
Above Terrain and the Height Of Terrain.

    HeightAboveTerrain   0
    HeightOfTerrain      1
    Extended             2

=cut

sub request_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'requestType'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x03;
    } else {
      carp "request_type must be 0 (HeightAboveTerrain), 1 (HeightOfTerrain), or 2 (Extended).";
    }
  }

  return ($self->{'_bitfields1'} & 0x03);
}

#==============================================================================

=item sub update_period([$newValue])

 $value = $hgt_rqst->update_period($newValue);

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

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $hgt_rqst->entity_ident($newValue);

Entity ID.

This attribute specifies the entity relative to which the test point is 
defined. This attribute is ignored if Coordinate System is set to Geodetic (0).

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub latitude([$newValue])

 $value = $hgt_rqst->latitude($newValue);

Latitude.

This attribute specifies the latitude from which the HAT/HOT request is being made.

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

 $value = $hgt_rqst->x_offset($newValue);

X Offset.

This attribute specifies the latitude from which the HAT/HOT request is being 
made. This value is given relative to the entity's reference point.

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

 $value = $hgt_rqst->longitude($newValue);

Longitude.

This attribute specifies the longitude from which the HAT/HOT request is being made.

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

 $value = $hgt_rqst->y_offset($newValue);

Y Offset.

This attribute specifies the longitude from which the HAT/HOT request is being 
made. This value is given relative to the entity's reference point.

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

 $value = $hgt_rqst->altitude($newValue);

Altitude.

This attribute specifies the altitude from which the HAT/HOT request is being 
made.
This attribute is ignored if Request Type is set to HOT (1).

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

 $value = $hgt_rqst->z_offset($newValue);

Z Offset.

This attribute specifies the altitude from which the HAT/HOT request is being 
made. This value is given relative to the entity's reference point.

=cut

sub z_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'altitude_zOffset'} = $nv;
  }
  return $self->{'altitude_zOffset'};
}

#==========================================================================

=item sub pack()

 $value = $hgt_rqst->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused41, coordinateSystem, and requestType.
        $self->{'updatePeriod'},
        $self->{'entityIdent'},
        $self->{'latitude_xOffset'},
        $self->{'longitude_yOffset'},
        $self->{'altitude_zOffset'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $hgt_rqst->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'requestIdent'}                        = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused41, coordinateSystem, and requestType.
  $self->{'updatePeriod'}                        = $e;
  $self->{'entityIdent'}                         = $f;
  $self->{'latitude_xOffset'}                    = $g;
  $self->{'longitude_yOffset'}                   = $h;
  $self->{'altitude_zOffset'}                    = $i;

  $self->{'coordinateSystem'}                    = $self->coordinate_system();
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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g,$j,$i,$l,$k);
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
