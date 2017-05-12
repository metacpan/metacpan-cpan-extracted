#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b2e04-200e-11de-bdce-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::PositionResponse;

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

Rinchi::CIGIPP::PositionResponse - Perl extension for the Common Image 
Generator Interface - Position Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::PositionResponse;
  my $pos_resp = Rinchi::CIGIPP::PositionResponse->new();

  $packet_type = $pos_resp->packet_type();
  $packet_size = $pos_resp->packet_size();
  $object_ident = $pos_resp->object_ident(8699);
  $articulated_part_ident = $pos_resp->articulated_part_ident(116);
  $coordinate_system = $pos_resp->coordinate_system(Rinchi::CIGIPP->ParentEntityCS);
  $object_class = $pos_resp->object_class(Rinchi::CIGIPP->ArticulatedPartOC);
  $latitude = $pos_resp->latitude(27.645);
  $x_offset = $pos_resp->x_offset(26.409);
  $longitude = $pos_resp->longitude(55.496);
  $y_offset = $pos_resp->y_offset(48.675);
  $altitude = $pos_resp->altitude(24.851);
  $z_offset = $pos_resp->z_offset(47.335);
  $roll = $pos_resp->roll(8.422);
  $pitch = $pos_resp->pitch(84.2);
  $yaw = $pos_resp->yaw(42.084);

=head1 DESCRIPTION

The Position Response packet is sent by the IG in response to a Position 
Request packet. This packet describes the position and orientation of an 
entity, articulated part, view, view group, or motion tracker.

=head2 EXPORT

None by default.

#==============================================================================

=item new $pos_resp = Rinchi::CIGIPP::PositionResponse->new()

Constructor for Rinchi::PositionResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b2e04-200e-11de-bdce-001c25551abc',
    '_Pack'                                => 'CCSCCSdddfffI',
    '_Swap1'                               => 'CCvCCvVVVVVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNNNNNN',
    'packetType'                           => 108,
    'packetSize'                           => 48,
    '_objectIdent'                         => 0,
    '_articulatedPartIdent'                => 0,
    '_bitfields1'                          => 0, # Includes bitfields coordinateSystem, and objectClass.
    '_unused78'                            => 0,
    'latitude_xOffset'                     => 0,
    'longitude_yOffset'                    => 0,
    'altitude_zOffset'                     => 0,
    'roll'                                 => 0,
    'pitch'                                => 0,
    'yaw'                                  => 0,
    '_unused79'                            => 0,
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

 $value = $pos_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Position Response packet. The 
value of this attribute must be 108.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $pos_resp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 48.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub object_ident([$newValue])

 $value = $pos_resp->object_ident($newValue);

Object ID.

This attribute identifies the entity, view, view group, or motion tracking 
device whose position is being reported. If Object Class is set to Articulated 
Part (1), this attribute indicates the entity whose part is identified by the 
Articulated Part ID attribute.

=cut

sub object_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'_objectIdent'} = $nv;
  }
  return $self->{'_objectIdent'};
}

#==============================================================================

=item sub articulated_part_ident([$newValue])

 $value = $pos_resp->articulated_part_ident($newValue);

Articulated Part ID.

This attribute identifies the articulated part whose position is being 
reported. The entity to which the part belongs is specified by the Object ID 
attribute.
This attribute is valid only when Object Class is set to Articulated Part (1).

=cut

sub articulated_part_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'_articulatedPartIdent'} = $nv;
  }
  return $self->{'_articulatedPartIdent'};
}

#==============================================================================

=item sub coordinate_system([$newValue])

 $value = $pos_resp->coordinate_system($newValue);

Coordinate System.

This attribute indicates the coordinate system in which the position and 
orientation are specified.

Geodetic – Position is specified as a geodetic latitude, longitude, and 
altitude. Orientation is given with respect to the reference plane.

Parent Entity – Position and orientation are with respect to the entity to 
which the specified child entity,  articulated part, view, or view group is 
attached. This  value is invalid for top-level entities.

Submodel – Position and orientation are with respect to the articulated part's 
reference coordinate system. This value is valid only when Object Class is set 
to Articulated Part (1).

Note: If Object Class is set to Motion Tracker (4), this attribute is ignored 
and the positional and rotational data are relative to the tracking device 
boresight state.

    GeodeticCS       0
    ParentEntityCS   1
    SubmodelCS       2

=cut

sub coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'_bitfields1'} |= ($nv << 3) &0x18;
    } else {
      carp "coordinate_system must be 0 (GeodeticCS), 1 (ParentEntityCS), or 2 (SubmodelCS).";
    }
  }
  return (($self->{'_bitfields1'} & 0x18) >> 3);
}

#==============================================================================

=item sub object_class([$newValue])

 $value = $pos_resp->object_class($newValue);

Object Class.

This attribute indicates the type of object whose position is being reported.

    EntityOC            0
    ArticulatedPartOC   1
    ViewOC              2
    ViewGroupOC         3
    MotionTrackerOC     4

=cut

sub object_class() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4)) {
      $self->{'_bitfields1'} |= $nv &0x07;
    } else {
      carp "object_class must be 0 (EntityOC), 1 (ArticulatedPartOC), 2 (ViewOC), 3 (ViewGroupOC), or 4 (MotionTrackerOC).";
    }
  }
  return ($self->{'_bitfields1'} & 0x07);
}

#==============================================================================

=item sub latitude([$newValue])

 $value = $pos_resp->latitude($newValue);

Latitude.          

If Coordinate System is set to Geodetic (0), this attribute indicates the 
geodetic latitude of the entity, articulated part, view, or view group.

=cut

sub latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-90) and ($nv<=90.0)) {
      $self->{'latitude_xOffset'} = $nv;
    } else {
      carp "latitude must be from -90.0 to +90.0.";
    }
  }
  return $self->{'latitude_xOffset'};
}

#==============================================================================

=item sub x_offset([$newValue])

 $value = $pos_resp->x_offset($newValue);

X Offset.

If Coordinate System is set to Parent Entity (1), this attribute indicates the 
X offset from the parent entity's origin to the child entity, articulated part, 
view, or view group.

If Coordinate System is set to Submodel (2), this attribute indicates the X 
offset from the articulated part submodel's reference point.

If Object Class is set to Motion Tracker (4), this attribute indicates the X 
position reported by the tracking device.

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

 $value = $pos_resp->longitude($newValue);

Longitude.          

If Coordinate System is set to Geodetic (0), this attribute indicates the 
geodetic longitude of the entity, articulated part, view, or view group.

=cut

sub longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-180.0) and ($nv<=180.0)) {
      $self->{'longitude_yOffset'} = $nv;
    } else {
      carp "longitude must be from -180.0 to +180.0.";
    }
  }
  return $self->{'longitude_yOffset'};
}

#==============================================================================

=item sub y_offset([$newValue])

 $value = $pos_resp->y_offset($newValue);

Y Offset.

If Coordinate System is set to Parent Entity (1), this attribute indicates the 
Y offset from the parent entity's origin to the child entity, articulated part, 
view, or view group.

If Coordinate System is set to Submodel (2), this attribute indicates the Y 
offset from the articulated part submodel's reference point.

If Object Class is set to Motion Tracker (4), this attribute indicates the Y 
position reported by the tracking device.

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

 $value = $pos_resp->altitude($newValue);

Altitude.

If Coordinate System is set to Geodetic (0), this attribute indicates the 
geodetic altitude of the entity, articulated part, view, or view group.

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

 $value = $pos_resp->z_offset($newValue);

Z Offset.        

If Coordinate System is set to Parent Entity (1), this attribute indicates the 
Z offset from the parent entity's origin to the child entity, articulated part, 
view, or view group.

If Coordinate System is set to Submodel (2), this attribute indicates the Z 
offset from the articulated part submodel's reference point.

If Object Class is set to Motion Tracker (4), this attribute indicates the Z 
position reported by the tracking device.

=cut

sub z_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'altitude_zOffset'} = $nv;
  }
  return $self->{'altitude_zOffset'};
}

#==============================================================================

=item sub roll([$newValue])

 $value = $pos_resp->roll($newValue);

Roll.

This attribute indicates the roll angle of the specified entity, articulated 
part, view, or view group.

If Object Class is set to Motion Tracker (4), this attribute indicates the roll 
angle reported by the tracking device.

=cut

sub roll() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-180.0) and ($nv<=180.0)) {
      $self->{'roll'} = $nv;
    } else {
      carp "roll must be from -180.0 to +180.0.";
    }
  }
  return $self->{'roll'};
}

#==============================================================================

=item sub pitch([$newValue])

 $value = $pos_resp->pitch($newValue);

Pitch.

This attribute indicates the pitch angle of the specified entity, articulated 
part, view, or view group.

If Object Class is set to Motion Tracker (4), this attribute indicates the 
pitch angle reported by the tracking device.

=cut

sub pitch() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-90) and ($nv<=90.0)) {
      $self->{'pitch'} = $nv;
    } else {
      carp "pitch must be from -90.0 to +90.0.";
    }
  }
  return $self->{'pitch'};
}

#==============================================================================

=item sub yaw([$newValue])

 $value = $pos_resp->yaw($newValue);

Yaw.

This attribute indicates the yaw angle of the specified entity, articulated 
part, view, or view group.

If Object Class is set to Motion Tracker (4), this attribute indicates the yaw 
angle reported by the tracking device.

=cut

sub yaw() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=0) and ($nv<=360.0)) {
      $self->{'yaw'} = $nv;
    } else {
      carp "yaw must be from 0.0 to +360.0.";
    }
  }
  return $self->{'yaw'};
}

#==========================================================================

=item sub pack()

 $value = $pos_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'_objectIdent'},
        $self->{'_articulatedPartIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused77, coordinateSystem, and objectClass.
        $self->{'_unused78'},
        $self->{'latitude_xOffset'},
        $self->{'longitude_yOffset'},
        $self->{'altitude_zOffset'},
        $self->{'roll'},
        $self->{'pitch'},
        $self->{'yaw'},
        $self->{'_unused79'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $pos_resp->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'_objectIdent'}                        = $c;
  $self->{'_articulatedPartIdent'}               = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused77, coordinateSystem, and objectClass.
  $self->{'_unused78'}                           = $f;
  $self->{'latitude_xOffset'}                    = $g;
  $self->{'longitude_yOffset'}                   = $h;
  $self->{'altitude_zOffset'}                    = $i;
  $self->{'roll'}                                = $j;
  $self->{'pitch'}                               = $k;
  $self->{'yaw'}                                 = $l;
  $self->{'_unused79'}                           = $m;

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g,$j,$i,$l,$k,$m,$n,$o,$p);
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
