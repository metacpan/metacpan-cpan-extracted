#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78aed68-200e-11de-bdb6-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::CollisionDetectionSegmentDefinition;

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

Rinchi::CIGIPP::CollisionDetectionSegmentDefinition - Perl extension for the 
Common Image Generator Interface - Collision Detection Segment Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::CollisionDetectionSegmentDefinition;
  my $cds_def = Rinchi::CIGIPP::CollisionDetectionSegmentDefinition->new();

  $packet_type = $cds_def->packet_type();
  $packet_size = $cds_def->packet_size();
  $entity_ident = $cds_def->entity_ident(58547);
  $segment_ident = $cds_def->segment_ident(64);
  $segment_enable = $cds_def->segment_enable(Rinchi::CIGIPP->Disable);
  $x1 = $cds_def->x1(27.907);
  $y1 = $cds_def->y1(79.193);
  $z1 = $cds_def->z1(1.157);
  $x2 = $cds_def->x2(42.937);
  $y2 = $cds_def->y2(47.855);
  $z2 = $cds_def->z2(49.825);
  $material_mask = $cds_def->material_mask(38021);

=head1 DESCRIPTION

The Collision Detection Segment Definition packet enables the Host to define 
one or more collision detection segments for an entity. A collision detection 
segment is a line segment along which collision testing is performed by the IG. 
When a collision detection segment intersects a polygon, the IG registers a 
collision by sending a Collision Detection Segment Notification (Section 
4.2.13) packet to the Host identifying the segment and the object with which it 
collided.
Note that collision detection testing is performed every frame by the IG.

The segment is defined by specifying the locations of its endpoints with 
respect to the associated entity's body coordinate system. 

Collision detection volumes (segments?) are tested segment-to-polygon. An 
entity will not perform collision detection segment testing against its own 
geometry.
If the Collision Detection Enable attribute of an Entity Control packet is set 
to Disabled (0), the referenced entity's segments will not be used for 
collision detection segment testing. If the state of an entity is set to 
Inactive/Standby (0) via the Entity State attribute of an Entity Control 
packet, neither that entity's segments nor its geometry will be included in 
collision detection segment testing.

If an entity is destroyed, any collision detection segments defined for that 
entity will also be destroyed.

Although non-entity collision detection segments may be defined by the IG 
configuration, the Host can only create collision detection segments by 
referencing an entity. If a segment must be defined along a non-entity object, 
the Host must first create an entity with no geometry (entity type zero) to 
represent that object.

Since collision tests are conducted at discrete moments in time, it is possible 
that a segment could pass completely through a polygon between successive 
tests, causing a missed collision. It may therefore be necessary for the IG to 
use segment sweeping or some other mechanism to avoid this situation.

=head2 EXPORT

None by default.

#==============================================================================

=item new $cds_def = Rinchi::CIGIPP::CollisionDetectionSegmentDefinition->new()

Constructor for Rinchi::CollisionDetectionSegmentDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78aed68-200e-11de-bdb6-001c25551abc',
    '_Pack'                                => 'CCSCCSffffffII',
    '_Swap1'                               => 'CCvCCvVVVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNNNN',
    'packetType'                           => 22,
    'packetSize'                           => 40,
    'entityIdent'                          => 0,
    'segmentIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused35, and segmentEnable.
    'segmentEnable'                        => 0,
    '_unused36'                            => 0,
    'x1'                                   => 0,
    'y1'                                   => 0,
    'z1'                                   => 0,
    'x2'                                   => 0,
    'y2'                                   => 0,
    'z2'                                   => 0,
    'materialMask'                         => 0,
    '_unused37'                            => 0,
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

 $value = $cds_def->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Collision Detection Segment 
Definition packet. The value of this attribute must be 22.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $cds_def->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 40.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $cds_def->entity_ident($newValue);

Entity ID.

This attribute specifies the entity for which the segment is defined.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub segment_ident([$newValue])

 $value = $cds_def->segment_ident($newValue);

Segment ID.

This attribute specifies the identifier of the segment. If a segment is already 
defined with the same Segment ID, that segment will be overwritten.

=cut

sub segment_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'segmentIdent'} = $nv;
  }
  return $self->{'segmentIdent'};
}

#==============================================================================

=item sub segment_enable([$newValue])

 $value = $cds_def->segment_enable($newValue);

Segment Enable.

This attribute specifies whether the segment is enabled or disabled. If it is 
set to Disable (0), the specified segment is ignored during collision testing.

    Disable   0
    Enable    1

=cut

sub segment_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'segmentEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "segment_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub x1([$newValue])

 $value = $cds_def->x1($newValue);

X1.

This attribute specifies the X offset of one endpoint of the collision segment. 
This offset is measured with respect to the coordinate system of the entity 
specified by the Entity ID attribute. The X offset of the other endpoint is 
defined by the X2 attribute.

=cut

sub x1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'x1'} = $nv;
  }
  return $self->{'x1'};
}

#==============================================================================

=item sub y1([$newValue])

 $value = $cds_def->y1($newValue);

Y1.

This attribute specifies the Y offset of one endpoint of the collision segment. 
This offset is measured with respect to the coordinate system of the entity 
specified by the Entity ID attribute. The Y offset of the other endpoint is 
defined by the Y2 attribute.

=cut

sub y1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'y1'} = $nv;
  }
  return $self->{'y1'};
}

#==============================================================================

=item sub z1([$newValue])

 $value = $cds_def->z1($newValue);

Z1.

This attribute specifies the Z offset of one endpoint of the collision segment. 
This offset is measured with respect to the coordinate system of the entity 
specified by the Entity ID attribute. The Z offset of the other endpoint is 
defined by the Z2 attribute.

=cut

sub z1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'z1'} = $nv;
  }
  return $self->{'z1'};
}

#==============================================================================

=item sub x2([$newValue])

 $value = $cds_def->x2($newValue);

X2.

This attribute specifies the X offset of one endpoint of the collision segment. 
This offset is measured with respect to the coordinate system of the entity 
specified by the Entity ID attribute. The X offset of the other endpoint is 
defined by the X1 attribute.

=cut

sub x2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'x2'} = $nv;
  }
  return $self->{'x2'};
}

#==============================================================================

=item sub y2([$newValue])

 $value = $cds_def->y2($newValue);

Y2.

This attribute specifies the Y offset of one endpoint of the collision segment. 
This offset is measured with respect to the coordinate system of the entity 
specified by the Entity ID attribute. The Y offset of the other endpoint is 
defined by the Y1 attribute.

=cut

sub y2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'y2'} = $nv;
  }
  return $self->{'y2'};
}

#==============================================================================

=item sub z2([$newValue])

 $value = $cds_def->z2($newValue);

Z2.

This attribute specifies theZ offset of one endpoint of the collision segment. 
This offset is measured with respect to the coordinate system of the entity 
specified by the Entity ID attribute. The Z offset of the other endpoint is 
defined by the Z1 attribute.

=cut

sub z2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'z2'} = $nv;
  }
  return $self->{'z2'};
}

#==============================================================================

=item sub material_mask([$newValue])

 $value = $cds_def->material_mask($newValue);

Material Mask.

This attribute specifies the environmental and cultural features to be included 
in or excluded from consideration for collision testing. Each bit represents a 
range of material code values. Setting that bit to one (1) will cause the IG to 
register hits with materials within the corresponding range.

Refer to the appropriate IG documentation for material code assignments.

=cut

sub material_mask() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'materialMask'} = $nv;
  }
  return $self->{'materialMask'};
}

#==========================================================================

=item sub pack()

 $value = $cds_def->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'segmentIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused35, and segmentEnable.
        $self->{'_unused36'},
        $self->{'x1'},
        $self->{'y1'},
        $self->{'z1'},
        $self->{'x2'},
        $self->{'y2'},
        $self->{'z2'},
        $self->{'materialMask'},
        $self->{'_unused37'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $cds_def->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'entityIdent'}                         = $c;
  $self->{'segmentIdent'}                        = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused35, and segmentEnable.
  $self->{'_unused36'}                           = $f;
  $self->{'x1'}                                  = $g;
  $self->{'y1'}                                  = $h;
  $self->{'z1'}                                  = $i;
  $self->{'x2'}                                  = $j;
  $self->{'y2'}                                  = $k;
  $self->{'z2'}                                  = $l;
  $self->{'materialMask'}                        = $m;
  $self->{'_unused37'}                           = $n;

  $self->{'segmentEnable'}                       = $self->segment_enable();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n);
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
