#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b3dea-200e-11de-bdd4-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::CollisionDetectionVolumeNotification;

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

Rinchi::CIGIPP::CollisionDetectionVolumeNotification - Perl extension for the 
Common Image Generator Interface - Collision Detection Volume Notification data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::CollisionDetectionVolumeNotification;
  my $cdv_ntc = Rinchi::CIGIPP::CollisionDetectionVolumeNotification->new();

  $packet_type = $cdv_ntc->packet_type();
  $packet_size = $cdv_ntc->packet_size();
  $entity_ident = $cdv_ntc->entity_ident(16373);
  $volume_ident = $cdv_ntc->volume_ident(83);
  $collision_type = $cdv_ntc->collision_type(Rinchi::CIGIPP->CollisionEntity);
  $contacted_entity_ident = $cdv_ntc->contacted_entity_ident(36408);
  $contacted_volume_ident = $cdv_ntc->contacted_volume_ident(60);

=head1 DESCRIPTION

The Collision Detection Volume Notification packet is used to notify the Host 
when a collision occurs between two collision detection volumes. Volumes 
belonging to the same entity are not tested against each other.

The IG sends a Collision Detection Volume Notification packet for each volume 
involved in a collision. For instance, if two volumes collide, two Collision 
Detection Volume Notification packets will be sent. If a collision occurs that 
involves three volumes, a total of six Collision Detection Volume Notification 
packets will be sent.

Unlike with collision detection segment testing, where the result is a single 
point, the result of a collision detection volume test is the geometric 
intersection of two volumes. This intersection is usually an irregular volume 
with many vertices; therefore, the collision response data contains no spatial 
information describing the intersection.

Because collision detection volume testing does not involve polygon surfaces, 
no material code is returned with the collision response data.

Note that collision detection testing is performed every frame by the IG. If a 
collision detection volume has been disabled, it will be excluded from all 
collision testing.

=head2 EXPORT

None by default.

#==============================================================================

=item new $cdv_ntc = Rinchi::CIGIPP::CollisionDetectionVolumeNotification->new()

Constructor for Rinchi::CollisionDetectionVolumeNotification.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b3dea-200e-11de-bdd4-001c25551abc',
    '_Pack'                                => 'CCSCCSCCSI',
    '_Swap1'                               => 'CCvCCvCCvV',
    '_Swap2'                               => 'CCnCCnCCnN',
    'packetType'                           => 114,
    'packetSize'                           => 16,
    'entityIdent'                          => 0,
    'volumeIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields, and collisionType.
    'collisionType'                        => 0,
    'contactedEntityIdent'                 => 0,
    'contactedVolumeIdent'                 => 0,
    '_unused85'                            => 0,
    '_unused86'                            => 0,
    '_unused87'                            => 0,
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

 $value = $cdv_ntc->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Collision Detection Volume 
Notification packet. The value of this attribute must be 114.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $cdv_ntc->packet_size();

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

 $value = $cdv_ntc->entity_ident($newValue);

Entity ID.

This attribute indicates the entity to which the collision detection volume belongs.

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

 $value = $cdv_ntc->volume_ident($newValue);

Volume ID.

This attribute indicates the ID of the collision detection volume within which 
the collision occurred.

This attribute, along with Entity ID, allows the Host to match this response 
with the corresponding request.

=cut

sub volume_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'volumeIdent'} = $nv;
  }
  return $self->{'volumeIdent'};
}

#==============================================================================

=item sub collision_type([$newValue])

 $value = $cdv_ntc->collision_type($newValue);

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

 $value = $cdv_ntc->contacted_entity_ident($newValue);

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

=item sub contacted_volume_ident([$newValue])

 $value = $cdv_ntc->contacted_volume_ident($newValue);

Contacted Volume ID.

This attribute indicates the ID of the collision detection volume with which 
the collision occurred.

=cut

sub contacted_volume_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'contactedVolumeIdent'} = $nv;
  }
  return $self->{'contactedVolumeIdent'};
}

#==========================================================================

=item sub pack()

 $value = $cdv_ntc->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'volumeIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused84, and collisionType.
        $self->{'contactedEntityIdent'},
        $self->{'contactedVolumeIdent'},
        $self->{'_unused85'},
        $self->{'_unused86'},
        $self->{'_unused87'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $cdv_ntc->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'entityIdent'}                         = $c;
  $self->{'volumeIdent'}                         = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused84, and collisionType.
  $self->{'contactedEntityIdent'}                = $f;
  $self->{'contactedVolumeIdent'}                = $g;
  $self->{'_unused85'}                           = $h;
  $self->{'_unused86'}                           = $i;
  $self->{'_unused87'}                           = $j;

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j);
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
