#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78afb28-200e-11de-bdbb-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::PositionRequest;

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

Rinchi::CIGIPP::PositionRequest - Perl extension for the Common Image Generator 
Interface - Position Request data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::PositionRequest;
  my $pos_rqst = Rinchi::CIGIPP::PositionRequest->new();

  $packet_type = $pos_rqst->packet_type();
  $packet_size = $pos_rqst->packet_size();
  $object_ident = $pos_rqst->object_ident(43377);
  $articulated_part_ident = $pos_rqst->articulated_part_ident(145);
  $coordinate_system = $pos_rqst->coordinate_system(Rinchi::CIGIPP->ParentEntityCS);
  $object_class = $pos_rqst->object_class(Rinchi::CIGIPP->EntityOC);
  $update_mode = $pos_rqst->update_mode(0);

=head1 DESCRIPTION

The Position Request packet is used to query the IG for the current position of 
an entity, articulated part, view,view group, or motion tracker. This feature 
is useful for determining the locations of autonomous IG-driven entities, child 
entities and articulated parts, and view eyepoints. It can also be used for 
determining the instantaneous position and orientation of head trackers and 
other tracked input devices.

=head2 EXPORT

None by default.

#==============================================================================

=item new $pos_rqst = Rinchi::CIGIPP::PositionRequest->new()

Constructor for Rinchi::PositionRequest.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78afb28-200e-11de-bdbb-001c25551abc',
    '_Pack'                                => 'CCSCCS',
    '_Swap1'                               => 'CCvCCv',
    '_Swap2'                               => 'CCnCCn',
    'packetType'                           => 27,
    'packetSize'                           => 8,
    'objectIdent'                          => 0,
    'articulatedPartIdent'                 => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused47, coordinateSystem, objectClass, and updateMode.
    'coordinateSystem'                     => 0,
    'objectClass'                          => 0,
    'updateMode'                           => 0,
    '_unused48'                            => 0,
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

 $value = $pos_rqst->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Position Request packet. The 
value of this attribute must be 27.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $pos_rqst->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 8.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub object_ident([$newValue])

 $value = $pos_rqst->object_ident($newValue);

Object ID.

This attribute identifies the entity, view, view group, or motion tracking 
device whose position is being requested.

If Object Class is set to Articulated Part (1), this attribute specifies the 
entity whose part is identified by the Articulated Part ID attribute.

=cut

sub object_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'objectIdent'} = $nv;
  }
  return $self->{'objectIdent'};
}

#==============================================================================

=item sub articulated_part_ident([$newValue])

 $value = $pos_rqst->articulated_part_ident($newValue);

Articulated Part ID.

This attribute identifies the articulated part whose position is being 
requested. The entity to which the part belongs is specified by the Object ID 
attribute. This attribute is valid only when Object Class is set to Articulated 
Part (1).

=cut

sub articulated_part_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'articulatedPartIdent' } = $nv;
  }
  return $self->{'articulatedPartIdent' };
}

#==============================================================================

=item sub coordinate_system([$newValue])

 $value = $pos_rqst->coordinate_system($newValue);

Coordinate System.

This attribute specifies the desired coordinate system relative to which the 
position and orientation should be given.

Geodetic – Position will be specified as a geodetic latitude, longitude, and 
altitude. Orientation is given with respect to the reference plane.

Parent Entity – Position and orientation are with respect to the entity to 
which the specified entity or view is attached. This value is invalid for 
top-level entities.

Submodel – Position and orientation will be specified with respect to the 
articulated part's reference coordinate system. This value is valid only when 
Object Class is set to Articulated Part (1).

Note: If Object Class is set to Motion Tracker (3), The coordinate system is 
defined by the tracking device and this attribute is ignored.

    GeodeticCS       0
    ParentEntityCS   1
    SubmodelCS       2

=cut

sub coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'coordinateSystem'}                     = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x30;
    } else {
      carp "coordinate_system must be 0 (GeodeticCS), 1 (ParentEntityCS), or 2 (SubmodelCS).";
    }
  }
  return (($self->{'_bitfields1'} & 0x30) >> 4);
}

#==============================================================================

=item sub object_class([$newValue])

 $value = $pos_rqst->object_class($newValue);

Object Class.

This attribute specifies the type of object whose position is being requested.

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
      $self->{'objectClass'}                          = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x0E;
    } else {
      carp "object_class must be 0 (EntityOC), 1 (ArticulatedPartOC), 2 (ViewOC), 3 (ViewGroupOC), or 4 (MotionTrackerOC).";
    }
  }
  return (($self->{'_bitfields1'} & 0x0E) >> 1);
}

#==============================================================================

=item sub update_mode([$newValue])

 $value = $pos_rqst->update_mode($newValue);

Update Mode.

This attribute specifies whether the IG should report the position of the 
requested object each frame. If this attribute is set to One-Shot (0), the IG 
should report the position only one time.

=cut

sub update_mode() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'updateMode'}                           = $nv;
    $self->{'_bitfields1'} |= $nv &0x01;
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==========================================================================

=item sub pack()

 $value = $pos_rqst->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'objectIdent'},
        $self->{'articulatedPartIdent' },
        $self->{'_bitfields1'},    # Includes bitfields unused47, coordinateSystem, objectClass, and updateMode.
        $self->{'_unused48'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $pos_rqst->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'objectIdent'}                         = $c;
  $self->{'articulatedPartIdent' }               = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused47, coordinateSystem, objectClass, and updateMode.
  $self->{'_unused48'}                           = $f;

  $self->{'coordinateSystem'}                    = $self->coordinate_system();
  $self->{'objectClass'}                         = $self->object_class();
  $self->{'updateMode'}                          = $self->update_mode();

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
  my ($a,$b,$c,$d,$e,$f) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f);
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
