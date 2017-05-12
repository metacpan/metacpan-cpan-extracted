#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b3b42-200e-11de-bdd3-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::CollisionDetectionSegmentNotification;

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

Rinchi::CIGIPP::CollisionDetectionSegmentNotification - Perl extension for the 
Common Image Generator Interface - Collision Detection Segment Notification 
data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::CollisionDetectionSegmentNotification;
  my $cds_ntc = Rinchi::CIGIPP::CollisionDetectionSegmentNotification->new();

  $packet_type = $cds_ntc->packet_type();
  $packet_size = $cds_ntc->packet_size();
  $entity_ident = $cds_ntc->entity_ident(22708);
  $segment_ident = $cds_ntc->segment_ident(165);
  $collision_type = $cds_ntc->collision_type(Rinchi::CIGIPP->CollisionEntity);
  $contacted_entity_ident = $cds_ntc->contacted_entity_ident(26345);
  $material_code = $cds_ntc->material_code(56614);
  $intersection_distance = $cds_ntc->intersection_distance(10.493);

=head1 DESCRIPTION

The Collision Detection Segment Notification packet is used to notify the Host 
when a collision occurs between a collision detection segment and a polygon. 
When a segment intersects a polygon whose material code matches the collision 
mask defined for the segment, the IG sends a Collision Detection Segment 
Notification packet indicating where and with what the collision occurred. If a 
segment intersects multiple polygons with material codes matching the mask, 
only the closest intersection is returned. Segments are not tested against 
polygons belonging to same the entity as the segment.

Note that collision detection testing is performed every frame by the IG. If a 
collision detection segment has been disabled, it will be excluded from all 
collision testing.

=head2 EXPORT

None by default.

#==============================================================================

=item new $cds_ntc = Rinchi::CIGIPP::CollisionDetectionSegmentNotification->new()

Constructor for Rinchi::CollisionDetectionSegmentNotification.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b3b42-200e-11de-bdd3-001c25551abc',
    '_Pack'                                => 'CCSCCSIf',
    '_Swap1'                               => 'CCvCCvVV',
    '_Swap2'                               => 'CCnCCnNN',
    'packetType'                           => 113,
    'packetSize'                           => 16,
    'entityIdent'                          => 0,
    'segmentIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused83, and collisionType.
    'collisionType'                        => 0,
    'contactedEntityIdent'                 => 0,
    'materialCode'                         => 0,
    'intersectionDistance'                 => 0,
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

 $value = $cds_ntc->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Collision Detection Segment 
Notification packet. The value of this attribute must be 113.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $cds_ntc->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $cds_ntc->entity_ident($newValue);

Entity ID.

This attribute indicates the entity to which the collision detection segment belongs.

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

 $value = $cds_ntc->segment_ident($newValue);

Segment ID.

This attribute indicates the ID of the collision detection segment along which 
the collision occurred.

This attribute, along with Entity ID, allows the Host to match this response 
with the corresponding request.

=cut

sub segment_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'segmentIdent'} = $nv;
  }
  return $self->{'segmentIdent'};
}

#==============================================================================

=item sub collision_type([$newValue])

 $value = $cds_ntc->collision_type($newValue);

Collision Type.

This attribute indicates whether the collision occurred with another entity or 
with a non-entity object such as the terrain.

    CollisionNonEntity   0
    CollisionEntity      1

=cut

sub collision_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'collisionType'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "collision_type must be 0 (CollisionNonEntity), or 1 (CollisionEntity).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub contacted_entity_ident([$newValue])

 $value = $cds_ntc->contacted_entity_ident($newValue);

Contacted Entity ID.

This attribute indicates the entity with which the collision occurred.

If Collision Type is set to Non-entity (0), this attribute is ignored.

=cut

sub contacted_entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'contactedEntityIdent'} = $nv;
  }
  return $self->{'contactedEntityIdent'};
}

#==============================================================================

=item sub material_code([$newValue])

 $value = $cds_ntc->material_code($newValue);

Material Code.

This attribute indicates the material code of the surface at the point of collision.

=cut

sub material_code() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'materialCode'} = $nv;
  }
  return $self->{'materialCode'};
}

#==============================================================================

=item sub intersection_distance([$newValue])

 $value = $cds_ntc->intersection_distance($newValue);

Intersection Distance.

This attribute indicates the distance along the collision test vector from the 
source endpoint (defined by the X1, Y1, and Z1 attributes in the Collision 
intersection. Detection Segment Definition packet) to the point of intersection.

=cut

sub intersection_distance() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'intersectionDistance'} = $nv;
  }
  return $self->{'intersectionDistance'};
}

#==========================================================================

=item sub pack()

 $value = $cds_ntc->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'segmentIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused83, and collisionType.
        $self->{'contactedEntityIdent'},
        $self->{'materialCode'},
        $self->{'intersectionDistance'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $cds_ntc->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'entityIdent'}                         = $c;
  $self->{'segmentIdent'}                        = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused83, and collisionType.
  $self->{'contactedEntityIdent'}                = $f;
  $self->{'materialCode'}                        = $g;
  $self->{'intersectionDistance'}                = $h;

  $self->{'collisionType'}                       = $self->collision_type();

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

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h);
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
