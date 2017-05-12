#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78af006-200e-11de-bdb7-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::CollisionDetectionVolumeDefinition;

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

Rinchi::CIGIPP::CollisionDetectionVolumeDefinition - Perl extension for the 
Common Image Generator Interface - Collision Detection Volume Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::CollisionDetectionVolumeDefinition;
  my $cdv_def = Rinchi::CIGIPP::CollisionDetectionVolumeDefinition->new();

  $packet_type = $cdv_def->packet_type();
  $packet_size = $cdv_def->packet_size();
  $entity_ident = $cdv_def->entity_ident(56515);
  $volume_ident = $cdv_def->volume_ident(33);
  $volume_type = $cdv_def->volume_type(Rinchi::CIGIPP->Sphere);
  $volume_enable = $cdv_def->volume_enable(Rinchi::CIGIPP->Enable);
  $x = $cdv_def->x(42.227);
  $y = $cdv_def->y(17.683);
  $z = $cdv_def->z(61.995);
  $radius = $cdv_def->radius(42.354);
  $height = $cdv_def->height(82.136);
  $width = $cdv_def->width(62.861);
  $depth = $cdv_def->depth(56.607);
  $roll = $cdv_def->roll(72.09);
  $pitch = $cdv_def->pitch(50.275);
  $yaw = $cdv_def->yaw(10.898);

=head1 DESCRIPTION

The Collision Detection Volume Definition packet enables the Host to define one 
or more collision detection volumes for an entity. A collision detection volume 
is a sphere or a cuboid through which collision testing is performed by the IG. 
When a collision detection volume passes through another collision detection 
volume, the IG registers a collision by sending a Collision Detection Volume 
Notification packet to the Host identifying the collided volumes.

Note that collision detection testing is performed every frame by the IG.

A volume is defined by specifying its location, size, and orientation with 
respect to the associated entity's body coordinate system. A sphere's size is 
specified as a radius; a cuboid's size is specified by its width, height, and 
depth.
Unlike collision detection segments, which are tested segment-to-polygon, 
collision detection volumes are tested volume-to-volume. Volumes associated 
with the same entity are not tested against each other.

Since collision tests are conducted at discrete moments in time, it is possible 
that two volumes could pass completely through one another between successive 
tests, causing a missed collision. It may therefore be necessary for the IG to 
use volume sweeping or some other mechanism to avoid this situation.

If the state of an entity is set to Inactive/Standby (0) via the Entity State 
attribute of an Entity Control packet, no collision detection volume testing 
will be performed for that entity.

If the Collision Detection Enable attribute of the Entity Control packet is set 
to Disabled (0), no volumes defined for the entity will be used as "source" 
volumes for collision testing.

If collision detection is enabled for two entities, two tests will be performed 
between each pair of volumes. This is because each volume will be used as both 
source and destination in each pair-wise test.

If an entity is destroyed, any collision detection volumes defined for that 
entity will also be destroyed.

Although non-entity collision detection volumes may be defined by the IG 
configuration, the Host can only create collision detection volumes by 
referencing an entity. If a volume must be defined about a non-entity object, 
the Host must first create an entity with no geometry (entity type zero) to 
represent that object.

=head2 EXPORT

None by default.

#==============================================================================

=item new $cdv_def = Rinchi::CIGIPP::CollisionDetectionVolumeDefinition->new()

Constructor for Rinchi::CollisionDetectionVolumeDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78af006-200e-11de-bdb7-001c25551abc',
    '_Pack'                                => 'CCSCCSfffffffffI',
    '_Swap1'                               => 'CCvCCvVVVVVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNNNNNN',
    'packetType'                           => 23,
    'packetSize'                           => 48,
    'entityIdent'                          => 0,
    'volumeIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused38, volumeType, and volumeEnable.
    'volumeType'                           => 0,
    'volumeEnable'                         => 0,
    '_unused39'                            => 0,
    'x'                                    => 0,
    'y'                                    => 0,
    'z'                                    => 0,
    'height_radius'                        => 0,
    'width'                                => 0,
    'depth'                                => 0,
    'roll'                                 => 0,
    'pitch'                                => 0,
    'yaw'                                  => 0,
    '_unused40'                            => 0,
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

 $value = $cdv_def->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Collision Detection Volume 
Definition packet. The value of this attribute must be 23.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $cdv_def->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 48.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $cdv_def->entity_ident($newValue);

Entity ID.

This attribute specifies the entity for which the volume is defined.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub volume_ident([$newValue])

 $value = $cdv_def->volume_ident($newValue);

Volume ID.

This attribute specifies the ID of the volume. If an ID is specified for which 
a volume is already defined, that volume will be overwritten.

=cut

sub volume_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'volumeIdent'} = $nv;
  }
  return $self->{'volumeIdent'};
}

#==============================================================================

=item sub volume_type([$newValue])

 $value = $cdv_def->volume_type($newValue);

Volume Type.

This attribute specified whether the volume is spherical or cuboid.

    Sphere   0
    Cuboid   1

=cut

sub volume_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'volumeType'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "volume_type must be 0 (Sphere), or 1 (Cuboid).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub volume_enable([$newValue])

 $value = $cdv_def->volume_enable($newValue);

Volume Enable.

This attribute specifies whether the volume is enabled or disabled. If it is 
set to Disable (0), the specified volume is ignored during collision testing.

    Disable   0
    Enable    1

=cut

sub volume_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'volumeEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "volume_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub x([$newValue])

 $value = $cdv_def->x($newValue);

X.

This attribute specifies the X offset of the center of the volume. This offset 
is measured with respect to the coordinate system of the entity specified by 
the Entity ID attribute.

=cut

sub x() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'x'} = $nv;
  }
  return $self->{'x'};
}

#==============================================================================

=item sub y([$newValue])

 $value = $cdv_def->y($newValue);

Y.

This attribute specifies the Y offset of the center of the volume. This offset 
is measured with respect to the coordinate system of the entity specified by 
the Entity ID attribute.

=cut

sub y() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'y'} = $nv;
  }
  return $self->{'y'};
}

#==============================================================================

=item sub z([$newValue])

 $value = $cdv_def->z($newValue);

Z.

This attribute specifies the Z offset of the center of the volume. This offset 
is measured with respect to the coordinate system of the entity specified by 
the Entity ID attribute.

=cut

sub z() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'z'} = $nv;
  }
  return $self->{'z'};
}

#==============================================================================

=item sub radius([$newValue])

 $value = $cdv_def->radius($newValue);

Radius.

For spherical collision detection volumes, this attribute specifies the radius 
of the sphere.

=cut

sub radius() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'height_radius'} = $nv;
  }
  return $self->{'height_radius'};
}

#==============================================================================

=item sub height([$newValue])

 $value = $cdv_def->height($newValue);

Height.

For cuboid collision detection volumes, this attribute specifies the length of 
the cuboid along its Z axis.

=cut

sub height() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'height_radius'} = $nv;
  }
  return $self->{'height_radius'};
}

#==============================================================================

=item sub width([$newValue])

 $value = $cdv_def->width($newValue);

Width.

For cuboid collision detection volumes, this attribute specifies the length of 
the cuboid along its Y axis. This attribute is ignored if Volume Type is set to 
Sphere (0).

=cut

sub width() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'width'} = $nv;
  }
  return $self->{'width'};
}

#==============================================================================

=item sub depth([$newValue])

 $value = $cdv_def->depth($newValue);

Depth.

For cuboid collision detection volumes, this attribute specifies the length of 
the cuboid along its X axis. This attribute is ignored if Volume Type is set to 
Sphere (0).

=cut

sub depth() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'depth'} = $nv;
  }
  return $self->{'depth'};
}

#==============================================================================

=item sub roll([$newValue])

 $value = $cdv_def->roll($newValue);

Roll.

For cuboid collision detection volumes, this attribute specifies the roll of 
the cuboid with respect to the entity's coordinate system. This attribute is 
ignored if Volume Type is set to Sphere (0).

=cut

sub roll() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'roll'} = $nv;
  }
  return $self->{'roll'};
}

#==============================================================================

=item sub pitch([$newValue])

 $value = $cdv_def->pitch($newValue);

Pitch.

For cuboid collision detection volumes, this attribute specifies the pitch of 
the cuboid with respect to the entity's coordinate system. This attribute is 
ignored if Volume Type is set to Sphere (0).

=cut

sub pitch() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'pitch'} = $nv;
  }
  return $self->{'pitch'};
}

#==============================================================================

=item sub yaw([$newValue])

 $value = $cdv_def->yaw($newValue);

Yaw.

For cuboid collision detection volumes, this attribute specifies the yaw of the 
cuboid with respect to the entity's coordinate system. This attribute is 
ignored if Volume Type is set to Sphere (0).

=cut

sub yaw() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'yaw'} = $nv;
  }
  return $self->{'yaw'};
}

#==========================================================================

=item sub pack()

 $value = $cdv_def->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'volumeIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused38, volumeType, and volumeEnable.
        $self->{'_unused39'},
        $self->{'x'},
        $self->{'y'},
        $self->{'z'},
        $self->{'height_radius'},
        $self->{'width'},
        $self->{'depth'},
        $self->{'roll'},
        $self->{'pitch'},
        $self->{'yaw'},
        $self->{'_unused40'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $cdv_def->unpack();

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
  $self->{'entityIdent'}                         = $c;
  $self->{'volumeIdent'}                         = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused38, volumeType, and volumeEnable.
  $self->{'_unused39'}                           = $f;
  $self->{'x'}                                   = $g;
  $self->{'y'}                                   = $h;
  $self->{'z'}                                   = $i;
  $self->{'height_radius'}                        = $j;
  $self->{'width'}                               = $k;
  $self->{'depth'}                               = $l;
  $self->{'roll'}                                = $m;
  $self->{'pitch'}                               = $n;
  $self->{'yaw'}                                 = $o;
  $self->{'_unused40'}                           = $p;

  $self->{'volumeType'}                          = $self->volume_type();
  $self->{'volumeEnable'}                        = $self->volume_enable();

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

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p);
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
