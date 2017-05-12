#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ab726-200e-11de-bda2-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::EntityControl;

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

Rinchi::CIGIPP::EntityControl - Perl extension for the Common Image Generator 
Interface - Entity Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::EntityControl;
  my $ent_ctl = Rinchi::CIGIPP::EntityControl->new();

  $packet_type = $ent_ctl->packet_type();
  $packet_size = $ent_ctl->packet_size();
  $entity_ident = $ent_ctl->entity_ident(18430);
  $ground_clamp = $ent_ctl->ground_clamp(0);
  $inherit_alpha = $ent_ctl->inherit_alpha(1);
  $collision_detection = $ent_ctl->collision_detection(1);
  $attach_state = $ent_ctl->attach_state(Rinchi::CIGIPP->Attach);
  $entity_state = $ent_ctl->entity_state(Rinchi::CIGIPP->EntityInactive);
  $extrapolation_enable = $ent_ctl->extrapolation_enable(Rinchi::CIGIPP->Disable);
  $animation_state = $ent_ctl->animation_state(Rinchi::CIGIPP->Stop);
  $animation_loop = $ent_ctl->animation_loop(Rinchi::CIGIPP->Continuous);
  $animation_direction = $ent_ctl->animation_direction(Rinchi::CIGIPP->Backward);
  $alpha = $ent_ctl->alpha(249);
  $entity_type = $ent_ctl->entity_type(54457);
  $parent_ident = $ent_ctl->parent_ident(38194);
  $roll = $ent_ctl->roll(36.539);
  $pitch = $ent_ctl->pitch(15.394);
  $yaw = $ent_ctl->yaw(53.214);
  $latitude = $ent_ctl->latitude(4.828);
  $x_offset = $ent_ctl->x_offset(22.092);
  $longitude = $ent_ctl->longitude(33.727);
  $y_offset = $ent_ctl->y_offset(71.648);
  $altitude = $ent_ctl->altitude(20.674);
  $z_offset = $ent_ctl->z_offset(81.962);

=head1 DESCRIPTION

The Entity Control packet is used to control position, attitude, and other 
attributes describing an entity's state. This packet may be applied to any 
entity in the simulation, including the Ownship.

Each entity is identified by a unique identifier called the Entity ID. When the 
Host sends an Entity Control packet to the IG, the IG sets the state of the 
entity object corresponding to the value of the Entity ID attribute. If the 
specified entity does not exist, the IG will create it.

When the IG creates an entity, it makes a copy of the geometry corresponding to 
the value of the Entity Type attribute. This copy exists as a unique and 
independent tree within the scene graph; therefore, any operations that modify 
an entity's tree (e.g., part articulations) affect only that entity and its 
children.
Entities can be attached to one another in a hierarchical relationship. In such 
a hierarchy, a child entity's position is specified relative to its parent's 
coordinate system. The Host needs only to control the parent entity in order to 
move all lower entities in the hierarchy as a group. No explicit manipulation 
of a child entity is necessary unless its position and attitude change with 
respect to its parent.

The Attach State attribute of the Entity Control packet determines whether an 
entity is attached to a parent. If this attribute is set to Attach (1), the 
entity is attached to the entity specified by the Parent ID attribute. The 
Entity State attribute is used to control when an entity is visible and when 
its geometry is loaded and unloaded. When an entity is created, the Entity 
State attribute can be set to Active to specify that the entity should be added 
to the scene as soon as the model geometry is loaded. The entity and any 
children can be made invisible at any time by setting Entity State to 
Inactive/Standby. When the entity is no longer needed, Entity State can be set 
to Destroyed to direct the IG to unload the geometry and free any memory 
allocated for the entity. Any children attached to the entity are also 
destroyed.
Models can be preloaded to increase the speed at which they can be initially 
displayed. For example, when an aircraft fires a missile, a new entity would 
need to be created for that missile. Unless the missile geometry is cached, the 
IG must load the model from its hard disk. Because of its tremendous speed, the 
missile might fly a significant distance (and possibly beyond visual range) 
before the disk I/O can be completed. By preloading the entity, the geometry 
can already exist in memory and be instantly activated within the scene graph 
when needed. To accomplish this, the Entity State flag could be set to 
Inactive/Standby when the missile is created. Later, when the missile is 
needed, an Entity Control packet for that entity would be sent containing the 
proper positional data and with the Entity State flag set to Active.

An entity can also be made invisible by setting the Alpha attribute to zero 
(0). This attribute specifies an alpha value to be applied to the entity's 
geometry. The Inherit Alpha attribute indicates whether a child entity's alpha 
value is combined with that of its parent. For example, a missile attached to 
the wing of an aircraft would typically be made invisible when the aircraft is 
destroyed, so its Inherit Alpha attribute would be set to Inherited (1). An 
explosion or similar animation attached to that aircraft, however, would 
typically linger after the aircraft's destruction, so its Inherit Alpha 
attribute would be set to Not Inherited (0).

Note that setting the Entity State attribute to Inactive/Standby is not 
equivalent to setting the Alpha attribute to zero (0). The Entity State 
attribute enables or disables the entity geometry in the scene graph. The 
entity would not be included in line of sight and collision testing, nor would 
any transformations be applied. Any children would also be disabled. The Alpha 
attribute, on the other hand, merely affects the opacity of the specified 
entity.
The positions of top-level entities (i.e., those entities that are not 
children) are always specified as a geodetic latitude, longitude, and altitude. 
The positions of child entities are always specified with respect to the 
parents' NED body coordinate system.

In certain instances, it is desirable for the IG to "clamp" the entity to the 
surface of the terrain. This can be used as an alternative to using HOT 
requests and responses to determine ground elevation and slope below the 
entity. If the Ground/Ocean Clamp attribute is set to Non-Conformal (1) or 
Conformal (2), the Altitude attribute specifies an offset above the ground or 
sea surface height. This is useful for specifying the vertical distance from an 
automobile's reference point to its wheels, for instance, or from a ship's 
reference point to its waterline. Similarly, Roll and Pitch specify rotational 
offsets if ground or ocean clamping is enabled.

The Animation State attribute is used to control the playback state of 
animation entities. To start the animation sequence, the Host will send an 
Entity Control packet with its Entity State set to Active and its Animation 
State attribute to either Play or Resume. The Host may explicitly stop the 
animation at any time by setting the Animation State to Stop. Setting the 
attribute to Pause freezes the animation sequence at the current frame. Setting 
the attribute to Resume in a subsequent frame will resume the animation from 
its paused state; setting it to Play will play the animation again from its 
initial state. Setting Animation State to Play during playback will restart the 
animation.
Note that setting the Animation State attribute to Stop will have different 
effects on different types of animations. Frame-based animations may simply 
stop, or begin a termination sequence if such a sequence has been defined, at 
the current frame. Emitter-based animations (e.g, missile trails and particle 
systems) will stop producing new particles or segments; however, existing 
particles or segments will continue to decay normally. Stopping an animation 
does not implicitly remove it from the scene unless the Entity State attribute 
is set to Inactive/Standby or Destroyed.

If an animation has been built with a limited duration, and if the Animation 
Loop Mode attribute is set to One-Shot, the animation will stop automatically 
upon its completion. The IG will indicate this condition by sending an 
Animation Stop Notification packet to the Host. If the Animation Loop Mode 
attribute is set to Loop, the animation will immediately restart from the 
beginning and no Animation Stop Notification packet will be sent.

Once an Entity Control packet describing an entity is sent to the IG, the state 
of that entity will not change until another Entity Control packet specifying 
that entity ID is received. For example, packets describing the Ownship and a 
wingman may be sent every frame to indicate continuous positional changes, 
while a packet describing an inactive SAM site may be sent once during mission initialization.

=head2 EXPORT

None by default.

#==============================================================================

=item new $ent_ctl = Rinchi::CIGIPP::EntityControl->new()

Constructor for Rinchi::EntityControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ab726-200e-11de-bda2-001c25551abc',
    '_Pack'                                => 'CCSCCCCSSfffddd',
    '_Swap1'                               => 'CCvCCCCvvVVVVVVVVV',
    '_Swap2'                               => 'CCnCCCCnnNNNNNNNNN',
    'packetType'                           => 2,
    'packetSize'                           => 48,
    'entityIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused3, groundClamp, inheritAlpha, collisionDetection, attachState, and entityState.
    'groundClamp'                          => 0,
    'inheritAlpha'                         => 0,
    'collisionDetection'                   => 0,
    'attachState'                          => 0,
    'entityState'                          => 0,
    '_bitfields2'                          => 0, # Includes bitfields unused4, extrapolationEnable, animationState, animationLoop, and animationDirection.
    'extrapolationEnable'                  => 0,
    'animationState'                       => 0,
    'animationLoop'                        => 0,
    'animationDirection'                   => 0,
    'alpha'                                => 0,
    '_unused5'                             => 0,
    'entityType'                           => 0,
    'parentIdent'                          => 0,
    'roll'                                 => 0,
    'pitch'                                => 0,
    'yaw'                                  => 0,
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

 $value = $ent_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Entity Control packet. The 
value of this attribute must be 2.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $ent_ctl->packet_size();

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

 $value = $ent_ctl->entity_ident($newValue);

Entity ID.

This attribute specifies the entity to which this packet will be applied. A 
value of zero (0) corresponds to the Ownship.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub ground_clamp([$newValue])

 $value = $ent_ctl->ground_clamp($newValue);

Ground/Ocean Clamp.

This attribute specifies whether the entity should be clamped to the ground or 
water surface. If Attach State is set to Attach (1), this attribute is ignored.

No Clamp – The entity is not clamped. The Altitude attribute specifies the 
entity's height above Mean Sea Level. The Pitch and Roll attributes specify the 
entity's pitch and roll relative to the geodetic reference plane.

Non-Conformal – The entity is clamped. The Altitude attribute specifies an 
offset above the terrain or sea level. The Pitch and Roll attributes specify 
the entity's pitch and roll relative to the geodetic reference plane. Conformal 
– The entity is clamped and its attitude conforms to the terrain. The Altitude 
attribute specifies an offset above the terrain or sea level. The Pitch and 
Roll attributes specify the entity's pitch and roll relative to the slope of 
the terrain or water.

=cut

sub ground_clamp() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'groundClamp'} = $nv;
    $self->{'_bitfields1'} |= ($nv << 5) &0x60;
  }
  return (($self->{'_bitfields1'} & 0x60) >> 5);
}

#==============================================================================

=item sub inherit_alpha([$newValue])

 $value = $ent_ctl->inherit_alpha($newValue);

Inherit Alpha

This attribute specifies whether the entity's alpha is combined with the 
apparent alpha of its parent.

Note that a change in an entity's alpha affects the entities below it in the 
hierarchy if those entities inherit their parents' alphas.

If Attach State is set to Detach (0), this attribute is ignored.

=cut

sub inherit_alpha() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'inheritAlpha'} = $nv;
    $self->{'_bitfields1'} |= ($nv << 4) &0x10;
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub collision_detection_enable([$newValue])

 $value = $ent_ctl->collision_detection_enable($newValue);

Collision Detection Enable.

This attribute determines whether any collision detection segments and volumes 
associated with this entity are used as the source in collision testing.

If this attribute is set to Enabled (1), every frame each collision detection 
segment is tested for intersections with polygons not associated with this 
entity and each collision detection volume is tested pair-wise with every other 
volume that is not associated with the entity.

If this attribute is set to Disabled (0), any collision detection segments 
defined for the entity are ignored and any collision detection volumes are only 
tested (as the destination) against volumes defined for entities whose 
collision detection is enabled.

    Disable   0
    Enable    1

=cut

sub collision_detection_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'collisionDetection'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "collision_detection_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub attach_state([$newValue])

 $value = $ent_ctl->attach_state($newValue);

Attach State.

This attribute specifies whether the entity should be attached as a child to a 
parent.
If this attribute is set to Detach (0), the entity becomes or remains a 
top-level (non-child) entity. The Parent ID attribute is ignored. The Yaw, 
Pitch, Roll, Latitude, Longitude, and Altitude attributes all specify the 
entity's position relative to the geodetic coordinate system.

If this attribute is set to Attach (1), the entity becomes or remains attached 
to the entity specified by the Parent ID attribute. The parent must already 
exist, having been created in a prior frame or earlier in the current frame. 
The Yaw, Pitch, Roll, X Offset, Y Offset, and Z Offset attributes all specify 
the entity's position relative to the parent's coordinate system.

This attribute may be changed for a given entity at any time. The attachment or 
detachment takes place immediately and remains in effect until changed with 
another Entity Control packet.

    Detach   0
    Attach   1

=cut

sub attach_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'attachState'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "attach_state must be 0 (Detach), or 1 (Attach).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub entity_state([$newValue])

 $value = $ent_ctl->entity_state($newValue);

Entity State.

This attribute specifies whether the entity should be active or destroyed. It 
may be set to one of the following values:

Inactive/Standby – The entity is loaded, but its tree is not enabled in the 
scene graph. The entity is invisible, and no transformations are applied. 
Additionally, the entity is excluded from line of sight and collision testing.

Active – The entity's tree is enabled in the scene graph. Transformations are 
applied to the entity and it is included in line of sight and collision 
testing.
Destroyed – The entity's tree is removed from the scene graph. Any children are 
also destroyed. All other attributes in this packet are ignored.

    EntityInactive    0
    EntityStandby     1
    EntityActive      1
    EntityDestroyed   2

=cut

sub entity_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==1) or ($nv==2)) {
      $self->{'entityState'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x03;
    } else {
      carp "entity_state must be 0 (EntityInactive), 1 (EntityStandby), 1 (EntityActive), or 2 (EntityDestroyed).";
    }
  }
  return ($self->{'_bitfields1'} & 0x03);
}

#==============================================================================

=item sub extrapolation_enable([$newValue])

 $value = $ent_ctl->extrapolation_enable($newValue);

Linear Extrapolation/Interpolation Enable

This attribute specifies whether the entity's motion may be smoothed by 
extrapolation or interpolation algorithms on the IG. Such smoothing may be 
useful for compensating for lost CIGI messages, irregular frame rates, 
asynchronous operation, etc.

If extrapolation or interpolation is disabled globally through the 
Extrapolation/Interpolation Enable flag of the IG Control packet, then 
smoothing will not be applied to the entity.

    Disable   0
    Enable    1

=cut

sub extrapolation_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'extrapolationEnable'} = $nv;
      $self->{'_bitfields2'} |= ($nv << 4) &0x10;
    } else {
      carp "extrapolation_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields2'} & 0x10) >> 4);
}

#==============================================================================

=item sub animation_state([$newValue])

 $value = $ent_ctl->animation_state($newValue);

Animation State.

This attribute specifies the state of an animation. This attribute applies only 
when the value of the Entity Type attribute corresponds to an animation.

Stop - Stops the animation sequence. If the animation has a termination 
sequence or decay behavior, the animation will switch to that behavior. Has no 
effect if the animation is currently stopped.

Pause - Pauses playback of an animation. The entity's geometry will remain 
visible, provided Entity State is set to Active.

Play - Begins or restarts playback from the first animation frame.

Continue - Continues a playing animation from the current frame of the 
animation sequence. If the animation is paused, playback is resumed from the 
current frame. If the animation is stopped, playback is restarted from the 
first frame of the sequence.

    Stop       0
    Pause      1
    Play       2
    Continue   3

=cut

sub animation_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3)) {
      $self->{'animationState'} = $nv;
      $self->{'_bitfields2'} |= ($nv << 2) &0x0C;
    } else {
      carp "animation_state must be 0 (Stop), 1 (Pause), 2 (Play), or 3 (Continue).";
    }
  }
  return (($self->{'_bitfields2'} & 0x0C) >> 2);
}

#==============================================================================

=item sub animation_loop([$newValue])

 $value = $ent_ctl->animation_loop($newValue);

Animation Loop Mode.

This attribute specifies whether an animation should be a one-shot (i.e., 
should play once and stop) or should loop continuously.

    OneShot      0
    Continuous   1

=cut

sub animation_loop() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'animationLoop'} = $nv;
      $self->{'_bitfields2'} |= ($nv << 1) &0x02;
    } else {
      carp "animation_loop must be 0 (OneShot), or 1 (Continuous).";
    }
  }
  return (($self->{'_bitfields2'} & 0x02) >> 1);
}

#==============================================================================

=item sub animation_direction([$newValue])

 $value = $ent_ctl->animation_direction($newValue);

Animation Direction.

This attribute specifies the direction in which an animation plays. This 
attribute applies only when the value of the Entity Type attribute corresponds 
to an animation.

    Forward    0
    Backward   1

=cut

sub animation_direction() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'animationDirection'} = $nv;
      $self->{'_bitfields2'} |= $nv &0x01;
    } else {
      carp "animation_direction must be 0 (Forward), or 1 (Backward).";
    }
  }
  return ($self->{'_bitfields2'} & 0x01);
}

#==============================================================================

=item sub alpha([$newValue])

 $value = $ent_ctl->alpha($newValue);

Alpha.

This attribute specifies the explicit alpha to be applied to the entity's 
geometry. A value of zero (0) corresponds to fully transparent; a value of 255 
corresponds to fully opaque.

=cut

sub alpha() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'alpha'} = $nv;
  }
  return $self->{'alpha'};
}

#==============================================================================

=item sub entity_type([$newValue])

 $value = $ent_ctl->entity_type($newValue);

Entity Type.

This attribute specifies the type of the entity. A value of zero (0) indicates 
a “null” type with no associated geometry. Such an entity might be used to 
represent the Ownship or a floating camera.

When changing entity types, the Host should first delete the entity by setting 
the Entity State attribute to Deactivate (2) and then recreate the entity and 
any children during a subsequent frame. If the specified type is undefined, the 
data packet will be disregarded.

=cut

sub entity_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityType'} = $nv;
  }
  return $self->{'entityType'};
}

#==============================================================================

=item sub parent_ident([$newValue])

 $value = $ent_ctl->parent_ident($newValue);

Parent ID.

This attribute specifies the parent for the entity. If the Attach State 
attribute is set to Detach (0), this attribute is ignored.

The value of this attribute may be changed without first detaching the entity 
from its existing parent.If the specified parent entity is invalid, no change 
in the attachment will be made.

=cut

sub parent_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'parentIdent'} = $nv;
  }
  return $self->{'parentIdent'};
}

#==============================================================================

=item sub roll([$newValue])

 $value = $ent_ctl->roll($newValue);

Roll.

This attribute specifies the roll angle of the entity.

For child entities, roll is measured from the entity's reference plane after 
yaw and pitch rotations have been applied.

For top-level entities for which Ground/Ocean Clamp is set to No Clamp (0) or 
Non-Conformal (1), this angle is measured from the reference plane.

For top-level entities for which Ground/Ocean Clamp is enabled, this angle 
specifies an angular offset from the terrain surface polygon's orientation.

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

 $value = $ent_ctl->pitch($newValue);

Pitch.

This attribute specifies the pitch angle of the entity.

For child entities, pitch is measured with respect to the entity's reference 
plane after the yaw rotation has been applied.

For top-level entities for which Ground/Ocean Clamp is set to No Clamp (0) or 
Non-Conformal (1), this angle is measured from the reference plane.

For top-level entities for which Ground/Ocean Clamp is enabled, this angle 
specifies an angular offset from the terrain surface polygon's orientation.

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

 $value = $ent_ctl->yaw($newValue);

Yaw.

For child entities, this attribute specifies a rotation about the child 
entity's Z axis when the child's X axis is parallel to the parent's X axis.

For top-level (non-child) entities, this attribute specifies the instantaneous 
heading of the entity. This angle is measured from a line parallel to the Prime Meridian.

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

#==============================================================================

=item sub latitude([$newValue])

 $value = $ent_ctl->latitude($newValue);

Latitude.

For top-level (non-child) entities, this attribute specifies the entity's 
geodetic latitude.

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

 $value = $ent_ctl->x_offset($newValue);

X Offset.

For child entities, this attribute represents the distance in meters from the 
parent's reference point along its parent's X axis.

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

 $value = $ent_ctl->longitude($newValue);

Longitude.

For top-level (non-child) entities, this attribute specifies the entity's 
geodetic longitude.

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

 $value = $ent_ctl->y_offset($newValue);

Y Offset.

For child entities, this attribute represents the distance in meters from the 
parent's reference point along its parent's Y axis.

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

 $value = $ent_ctl->altitude($newValue);

Altitude.

For top-level (non-child) entities, this attribute specifies the entity's 
geodetic altitude.

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

 $value = $ent_ctl->z_offset($newValue);

Z Offset.

For child entities, this attribute represents the distance in meters from the 
parent's reference point along its parent's Z axis.

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

 $value = $ent_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused3, groundClamp, inheritAlpha, collisionDetection, attachState, and entityState.
        $self->{'_bitfields2'},    # Includes bitfields unused4, extrapolationEnable, animationState, animationLoop, and animationDirection.
        $self->{'alpha'},
        $self->{'_unused5'},
        $self->{'entityType'},
        $self->{'parentIdent'},
        $self->{'roll'},
        $self->{'pitch'},
        $self->{'yaw'},
        $self->{'latitude_xOffset'},
        $self->{'longitude_yOffset'},
        $self->{'altitude_zOffset'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ent_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                         = $a;
  $self->{'packetSize'}                         = $b;
  $self->{'entityIdent'}                        = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused3, groundClamp, inheritAlpha, collisionDetection, attachState, and entityState.
  $self->{'_bitfields2'}                         = $e; # Includes bitfields unused4, extrapolationEnable, animationState, animationLoop, and animationDirection.
  $self->{'alpha'}                              = $f;
  $self->{'_unused5'}                            = $g;
  $self->{'entityType'}                         = $h;
  $self->{'parentIdent'}                        = $i;
  $self->{'roll'}                               = $j;
  $self->{'pitch'}                              = $k;
  $self->{'yaw'}                                = $l;
  $self->{'latitude_xOffset'}                   = $m;
  $self->{'longitude_yOffset'}                  = $n;
  $self->{'altitude_zOffset'}                   = $o;

  $self->{'groundClamp'}                        = $self->ground_clamp();
  $self->{'inheritAlpha'}                       = $self->inherit_alpha();
  $self->{'collisionDetection'}                 = $self->collision_detection_enable();
  $self->{'attachState'}                        = $self->attach_state();
  $self->{'entityState'}                        = $self->entity_state();
  $self->{'extrapolationEnable'}                = $self->extrapolation_enable();
  $self->{'animationState'}                     = $self->animation_state();
  $self->{'animationLoop'}                      = $self->animation_loop();
  $self->{'animationDirection'}                 = $self->animation_direction();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$n,$m,$p,$o,$r,$q);
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
