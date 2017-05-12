#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b0078-200e-11de-bdbd-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SymbolSurfaceDefinition;

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

Rinchi::CIGIPP::SymbolSurfaceDefinition - Perl extension for the Common Image 
Generator Interface - Symbol Surface Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SymbolSurfaceDefinition;
  my $sym_surf = Rinchi::CIGIPP::SymbolSurfaceDefinition->new();

  $packet_type = $sym_surf->packet_type();
  $packet_size = $sym_surf->packet_size();
  $surface_ident = $sym_surf->surface_ident(35085);
  $perspective_growth_enable = $sym_surf->perspective_growth_enable(Rinchi::CIGIPP->Enabled);
  $billboard = $sym_surf->billboard(Rinchi::CIGIPP->Billboard);
  $attach_type = $sym_surf->attach_type(Rinchi::CIGIPP->ViewAT);
  $surface_state = $sym_surf->surface_state(Rinchi::CIGIPP->DestroyedSS);
  $entity_ident = $sym_surf->entity_ident(47752);
  $view_ident = $sym_surf->view_ident(58180);
  $x_offset = $sym_surf->x_offset(40.156);
  $left = $sym_surf->left(30.873);
  $y_offset = $sym_surf->y_offset(36.278);
  $right = $sym_surf->right(65.423);
  $z_offset = $sym_surf->z_offset(64.092);
  $top = $sym_surf->top(30.89);
  $yaw = $sym_surf->yaw(0.109);
  $bottom = $sym_surf->bottom(5.179);
  $pitch = $sym_surf->pitch(80.979);
  $roll = $sym_surf->roll(61.448);
  $width = $sym_surf->width(83.426);
  $height = $sym_surf->height(47.941);
  $min_u = $sym_surf->min_u(31.315);
  $max_u = $sym_surf->max_u(53.721);
  $min_v = $sym_surf->min_v(16.873);
  $max_v = $sym_surf->max_v(34.874);

=head1 DESCRIPTION

The Symbol Surface Definition packet is used to create a symbol surface and 
control its position, orientation,size, and other attributes.

Each symbol surface is identified by a unique Surface ID value. When the IG 
receives a Symbol Surface Definition packet referring to a surface that does 
not exist, the IG creates a new surface based on the packet'sattributes. If the 
surface does exist, it is modified according to the packet's attributes. 

A symbol surface must be attached to exactly one entity or view. The Attach 
Type attribute determines the typeof object to which the view is attached, and 
the Entity ID/View ID attribute identifies that object. If the entity or view 
does not exist, the Symbol Surface Definition packet is ignored. 

For surfaces attached to a view, the Left, Right, Top, and Bottom attributes 
define the position and size of the surface. These values are specified 
relative to the view's Normalized Viewport Coordinate System as described in 
CIGI ICD Section 3.4.4.3.

For non-billboard surfaces attached to an entity, the X Offset, Y Offset, Z 
Offset, Yaw, Pitch, and Roll attributes specify the position and attitude of 
the surface in relation to the entity to which it is attached. The translation 
and rotation behavior is the same as for a child entity and is described in 
CIGI ICD Section 3.4.4.1. The Width and Height attributes specify the size of 
the surface.

For billboard surfaces attached to an entity, the X Offset, Y Offset, and Z 
Offset attributes define the distance from the surface to the entity. The 
orientation of the entity has no effect on the view's orientation; the view is 
always parallel to the view plane as described in CIGI ICD Section Section 
3.4.4.2. The Width and Height attributes specify the size of the surface. The 
Yaw, Pitch, and Roll attributes are ignored. Every surface has a local 2D (UV) 
coordinate system that is used to place, rotate, and size of each symbol drawn 
on the surface as described in CIGI ICD Section 3.4.5.1. The Min U, Max U, Min 
V, and Max V attributes define this coordinate system.

The stacking order for surfaces attached to the same view is such that a 
surface with a lower Surface ID value is drawn behind (i.e., further from the 
eyepoint than) a surface with a higher value. For example, if three surfaces 
attached to the same view have Surface ID values of 3, 4, and 7, then Surface 3 
is drawn first. Surface 4 is drawn next and may occult any overlapping areas. 
Finally, Surface 7 is drawn on top and may likewise occult parts of the other 
surfaces.
Any surface attached to an entity is contained in the scene and is drawn with 
entities and other objects also in the scene. Since surfaces attached to views 
are coincident with the near clipping plane, view-attached surfaces ared rawn 
on top of all other objects in the view.

Once a Symbol Surface Definition packet describing a symbol surface is sent to 
the IG, the state of that surface will not change until another Symbol Surface 
Definition packet referencing the same Surface ID is received.

A symbol surface is destroyed by setting the Surface State attribute to 
Destroyed (1). Any symbols associated with that surface are also destroyed.

If an entity is destroyed, then any symbol surfaces attached to that entity are 
also destroyed.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sym_surf = Rinchi::CIGIPP::SymbolSurfaceDefinition->new()

Constructor for Rinchi::SymbolSurfaceDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b0078-200e-11de-bdbd-001c25551abc',
    '_Pack'                                => 'CCSCCSffffffffffff',
    '_Swap1'                               => 'CCvCCvVVVVVVVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNNNNNNNN',
    'packetType'                           => 29,
    'packetSize'                           => 56,
    'surfaceIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused51, perspectiveGrowthEnable, billboard, attachType, and surfaceState.
    'perspectiveGrowthEnable'              => 0,
    'billboard'                            => 0,
    'attachType'                           => 0,
    'surfaceState'                         => 0,
    '_unused52'                            => 0,
    'entityIdent_viewIdent'                => 0,
    'xOffset_left'                         => 0,
    'yOffset_right'                        => 0,
    'zOffset_top'                          => 0,
    'yaw_bottom'                           => 0,
    'pitch'                                => 0,
    'roll'                                 => 0,
    'width'                                => 0,
    'height'                               => 0,
    'minU'                                 => 0,
    'maxU'                                 => 0,
    'minV'                                 => 0,
    'maxV'                                 => 0,
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

 $value = $sym_surf->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Symbol Surface Definition 
packet. The value of this attribute must be 29.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sym_surf->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 56.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub surface_ident([$newValue])

 $value = $sym_surf->surface_ident($newValue);

Surface ID.

This attribute specifies the symbol surface to which this packet is applied.

Values 0 through 32767 are used for Host-defined symbols. Values of 32768 
through 65535 are reserved for IG-defined symbols. The Host may redefine these.

=cut

sub surface_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'surfaceIdent'} = $nv;
  }
  return $self->{'surfaceIdent'};
}

#==============================================================================

=item sub perspective_growth_enable([$newValue])

 $value = $sym_surf->perspective_growth_enable($newValue);

Perspective Growth Enable.

This attribute specifies whether the surface appears to maintain a constant 
size or has perspective growth as the entity to which the surface is attached 
moves closer to the eyepoint.

If the surface is attached to an entity and is a billboard, and if this 
attribute is set to Disabled (0), then the surface will appear to stay the same 
size (i.e., will cover the same area of the view) regardless of its distance 
from the eyepoint.

If the surface is attached to an entity and is a billboard, and if this 
attribute is set to Enabled (1), then the surface will appear to change size 
relative to the viewport as the entity to which the surface is attached moves 
away from or closer to the eyepoint.

If the surface is attached to an entity but is not a billboard, then this 
attribute is ignored.

If the surface is attached to a view, this attribute is ignored.

    Disabled   0
    Enabled    1

=cut

sub perspective_growth_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'perspectiveGrowthEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "perspective_growth_enable must be 0 (Disabled), or 1 (Enabled).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub billboard([$newValue])

 $value = $sym_surf->billboard($newValue);

Billboard.

This attribute specifies whether the surface is treated as a billboard.

If the surface is attached to an entity and this value is set to Non-Billboard 
(0), then the orientation of the surface is specified in relation to the 
entity's local coordinate system by the Yaw, Pitch, and Roll attributes.

If the surface is attached to an entity and this value is set to Billboard (1), 
then a normal vector from the center of the surface will be parallel to the 
viewing vector as shown in CIGI ICD Figure 25.

If the surface is attached to a view, then this attribute is ignored.

    NonBillboard   0
    Billboard      1

=cut

sub billboard() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'billboard'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "billboard must be 0 (NonBillboard), or 1 (Billboard).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub attach_type([$newValue])

 $value = $sym_surf->attach_type($newValue);

Attach Type.

This attribute specifies whether the surface should be attached to an entity or 
a view.

If the specified entity or view does not exist, this packet is ignored.

    EntityAT   0
    ViewAT     1

=cut

sub attach_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'attachType'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "attach_type must be 0 (EntityAT), or 1 (ViewAT).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub surface_state([$newValue])

 $value = $sym_surf->surface_state($newValue);

Surface State.

This attribute specifies whether the symbol surface should be active or 
destroyed.
Active – The surface is active and symbols may be drawn on it. The surface can 
be positioned, oriented, and sized; and it can be attached to an entity or a 
view.
Destroyed – The surface is removed from the system. Any symbols drawn to it are 
also destroyed. All other attributes in this packet are ignored.

    ActiveSS      0
    DestroyedSS   1

=cut

sub surface_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'surfaceState'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "surface_state must be 0 (ActiveSS), or 1 (DestroyedSS).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $sym_surf->entity_ident($newValue);

Entity ID.

This attribute specifies the entity to which this surface is attached.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub view_ident([$newValue])

 $value = $sym_surf->view_ident($newValue);

View ID.

This attribute specifies the view to which this surface is attached.

=cut

sub view_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'viewIdent'} = $nv;
  }
  return $self->{'viewIdent'};
}

#==============================================================================

=item sub x_offset([$newValue])

 $value = $sym_surf->x_offset($newValue);

X Offset. For a non-billboard surface attached to an entity, this attribute 
specifies the distance along the entity's X axis from the entity's reference 
point to the center of the surface (see CIGI ICD Section 3.4.4.1).

For a billboard surface attached to an entity, this attribute specifies the 
distance along the surface's X axis from the center of the surface to the 
entity's reference point (see CIGI ICD Section 3.4.4.2).

=cut

sub x_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'xOffset'} = $nv;
  }
  return $self->{'xOffset'};
}

#==============================================================================

=item sub left([$newValue])

 $value = $sym_surf->left($newValue);

Left.

For a surface attached to a view, this attribute specifies the distance from 
the left edge of the viewport to the surface's leftmost boundary as a fraction 
of the viewport's width (see CIGI ICD Section 3.4.4.3).

=cut

sub left() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'left'} = $nv;
  }
  return $self->{'left'};
}

#==============================================================================

=item sub y_offset([$newValue])

 $value = $sym_surf->y_offset($newValue);

Y Offset.

For a non-billboard surface attached to an entity, this attribute specifies the 
distance along the entity's Y axis from the entity's reference point to the 
center of the surface (see CIGI ICD Section 3.4.4.1).

For a billboard surface attached to an entity, this attribute specifies the 
distance along the surface's Y axis from the center of the surface to the 
entity's reference point (see CIGI ICD Section 3.4.4.2).

=cut

sub y_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'yOffset'} = $nv;
  }
  return $self->{'yOffset'};
}

#==============================================================================

=item sub right([$newValue])

 $value = $sym_surf->right($newValue);

Right.

For a surface attached to a view, this attribute specifies the distance from 
the left edge of the viewport to the surface's rightmost boundary as a fraction 
of the viewport's width (see CIGI ICD Section 3.4.4.3).

=cut

sub right() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'right'} = $nv;
  }
  return $self->{'right'};
}

#==============================================================================

=item sub z_offset([$newValue])

 $value = $sym_surf->z_offset($newValue);

Z Offset.

For a non-billboard surface attached to an entity, this attribute specifies the 
distance along the entity's Z axis from the entity's reference point to the 
center of the surface (see CIGI ICD Section 3.4.4.1).

For a billboard surface attached to an entity, this attribute specifies the 
distance along the surface's Z axis from the center of the surface to the 
entity's reference point (see CIGI ICD Section 3.4.4.2).

=cut

sub z_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'zOffset'} = $nv;
  }
  return $self->{'zOffset'};
}

#==============================================================================

=item sub top([$newValue])

 $value = $sym_surf->top($newValue);

Top.

For a surface attached to a view, this attribute specifies the distance from 
the bottom edge of the viewport to the surface's topmost boundary as a fraction 
of the viewport's height (see CIGI ICD Section 3.4.4.3).

=cut

sub top() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'top'} = $nv;
  }
  return $self->{'top'};
}

#==============================================================================

=item sub yaw([$newValue])

 $value = $sym_surf->yaw($newValue);

Yaw.

For a non-billboard surface attached to an entity, this attribute specifies a 
rotation about the surface's Z axis as described in CIGI ICD Section 3.4.4.1

For entity-attached billboard surfaces, this attribute is ignored.

=cut

sub yaw() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'yaw'} = $nv;
  }
  return $self->{'yaw'};
}

#==============================================================================

=item sub bottom([$newValue])

 $value = $sym_surf->bottom($newValue);

Bottom.

For a surface attached to a view, this attribute specifies the distance from 
the bottom edge of the viewport to the surface's bottommost boundary as a 
fraction of the viewport's height (see CIGI ICD Section 3.4.4.3).

=cut

sub bottom() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'bottom'} = $nv;
  }
  return $self->{'bottom'};
}

#==============================================================================

=item sub pitch([$newValue])

 $value = $sym_surf->pitch($newValue);

Pitch.

For a non-billboard surface attached to an entity, this attribute specifies a 
rotation about the surface's Y axis as described in CIGI ICD Section 3.4.4.1

For entity-attached billboard surfaces, this attribute is ignored.

For a surface attached to a view, this attribute is ignored.

=cut

sub pitch() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'pitch'} = $nv;
  }
  return $self->{'pitch'};
}

#==============================================================================

=item sub roll([$newValue])

 $value = $sym_surf->roll($newValue);

Roll.

For a non-billboard surface attached to an entity, this attribute specifies a 
rotation about the surface's X axis as described in SCIGI ICD ection 3.4.4.1

For entity-attached billboard surfaces, this attribute is ignored.

For a surface attached to a view, this attribute is ignored.

=cut

sub roll() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'roll'} = $nv;
  }
  return $self->{'roll'};
}

#==============================================================================

=item sub width([$newValue])

 $value = $sym_surf->width($newValue);

Width.

If the surface is attached to an entity and is not a billboard, then this 
attribute specifies the width of the surface in meters.

If the surface is attached to an entity and is a billboard, and if Perspective 
Growth Enable is set to Enabled (1), then this attribute specifies the width of 
the surface in meters. The apparent size of the surface will depend upon the 
distance to the surface from the eyepoint.

If the surface is attached to an entity and is a billboard, and if Perspective 
Growth Enable is set to Disabled (0), then this attribute specifies the width 
as a view arc and the occupied view space remains constant regardless of the 
surface's distance from the eyepoint.

If the surface is attached to a view, this attribute is ignored.

=cut

sub width() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'width'} = $nv;
  }
  return $self->{'width'};
}

#==============================================================================

=item sub height([$newValue])

 $value = $sym_surf->height($newValue);

Height.

If the surface is attached to an entity and is not a billboard, then this 
attribute specifies the width of the surface in meters.

If the surface is attached to an entity and is a billboard, and if Perspective 
Growth Enable is set to Enabled (1), then this attribute specifies the width of 
the surface in meters. The apparent size of the surface will depend upon the 
distance to the surface from the eyepoint.

If the surface is attached to an entity and is a billboard, and if Perspective 
Growth Enable is set to Disabled (0), then this attribute specifies the width 
as a view arc and the occupied view space remains constant regardless of the 
surface's distance from the eyepoint.

If the surface is attached to a view, this attribute is ignored.

=cut

sub height() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'height'} = $nv;
  }
  return $self->{'height'};
}

#==============================================================================

=item sub min_u([$newValue])

 $value = $sym_surf->min_u($newValue);

Min U.

This attribute specifies the minimum U coordinate of the symbol surface's 
viewable area. In other words, this attribute specifies the U coordinate that 
will correspond to the leftmost boundary of the symbol surface.

Symbol surface 2D coordinate systems and horizontal units are described in CIGI 
ICD Section 3.4.5.1.

=cut

sub min_u() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'minU'} = $nv;
  }
  return $self->{'minU'};
}

#==============================================================================

=item sub max_u([$newValue])

 $value = $sym_surf->max_u($newValue);

Max U.

This attribute specifies the maximum U coordinate of the symbol surface's 
viewable area. In other words, this attribute specifies the U coordinate that 
will correspond to the rightmost boundary of the symbol surface.

Symbol surface 2D coordinate systems and horizontal units are described in CIGI 
ICD Section 3.4.5.1.

=cut

sub max_u() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'maxU'} = $nv;
  }
  return $self->{'maxU'};
}

#==============================================================================

=item sub min_v([$newValue])

 $value = $sym_surf->min_v($newValue);

Min V.

This attribute specifies the minimum V coordinate of the symbol surface's 
viewable area. In other words, this attribute specifies the U coordinate that 
will correspond to the bottommost boundary of the symbol surface.

Symbol surface 2D coordinate systems and vertical units are described in CIGI 
ICD Section 3.4.5.1.

=cut

sub min_v() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'minV'} = $nv;
  }
  return $self->{'minV'};
}

#==============================================================================

=item sub max_v([$newValue])

 $value = $sym_surf->max_v($newValue);

Max V.

This attribute specifies the maximum V coordinate of the symbol surface's 
viewable area. In other words, this attribute specifies the U coordinate that 
will correspond to the topmost boundary of the symbol surface.

Symbol surface 2D coordinate systems and vertical units are described in CIGI 
ICD Section 3.4.5.1.

=cut

sub max_v() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'maxV'} = $nv;
  }
  return $self->{'maxV'};
}

#==========================================================================

=item sub pack()

 $value = $sym_surf->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'surfaceIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused51, perspectiveGrowthEnable, billboard, attachType, and surfaceState.
        $self->{'_unused52'},
        $self->{'entityIdent_viewIdent'},
        $self->{'xOffset_left'},
        $self->{'yOffset_right'},
        $self->{'zOffset_top'},
        $self->{'yaw_bottom'},
        $self->{'pitch'},
        $self->{'roll'},
        $self->{'width'},
        $self->{'height'},
        $self->{'minU'},
        $self->{'maxU'},
        $self->{'minV'},
        $self->{'maxV'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sym_surf->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'surfaceIdent'}                        = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused51, perspectiveGrowthEnable, billboard, attachType, and surfaceState.
  $self->{'_unused52'}                           = $e;
  $self->{'entityIdent_viewIdent'}               = $f;
  $self->{'xOffset_left'}                        = $g;
  $self->{'yOffset_right'}                       = $h;
  $self->{'zOffset_top'}                         = $i;
  $self->{'yaw_bottom'}                          = $j;
  $self->{'pitch'}                               = $k;
  $self->{'roll'}                                = $l;
  $self->{'width'}                               = $m;
  $self->{'height'}                              = $n;
  $self->{'minU'}                                = $o;
  $self->{'maxU'}                                = $p;
  $self->{'minV'}                                = $q;
  $self->{'maxV'}                                = $r;

  $self->{'perspectiveGrowthEnable'}             = $self->perspective_growth_enable();
  $self->{'billboard'}                           = $self->billboard();
  $self->{'attachType'}                          = $self->attach_type();
  $self->{'surfaceState'}                        = $self->surface_state();

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

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r);
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
