#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ac7ac-200e-11de-bda8-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::RateControl;

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

Rinchi::CIGIPP::RateControl - Perl extension for the Common Image Generator 
Interface - Rate Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::RateControl;
  my $rate_ctl = Rinchi::CIGIPP::RateControl->new();

  $packet_type = $rate_ctl->packet_type();
  $packet_size = $rate_ctl->packet_size();
  $entity_ident = $rate_ctl->entity_ident(5635);
  $articulated_part_ident = $rate_ctl->articulated_part_ident(210);
  $coordinate_system = $rate_ctl->coordinate_system(Rinchi::CIGIPP->World_Parent);
  $apply_to_articulated_part = $rate_ctl->apply_to_articulated_part(Rinchi::CIGIPP->True);
  $x_linear_rate = $rate_ctl->x_linear_rate(6.206);
  $y_linear_rate = $rate_ctl->y_linear_rate(32.738);
  $z_linear_rate = $rate_ctl->z_linear_rate(84.401);
  $roll_angular_rate = $rate_ctl->roll_angular_rate(47.174);
  $pitch_angular_rate = $rate_ctl->pitch_angular_rate(25.245);
  $yaw_angular_rate = $rate_ctl->yaw_angular_rate(36.996);

=head1 DESCRIPTION

The Rate Control packet is used to define linear and angular rates for entities 
and articulated parts.

The Rate Control packet is useful for models and submodels whose behavior is 
predictable and whose exact positions need not be known each frame by the Host. 
A rotating radar dish on a ground target, for example, revolves in a consistent 
manner, and the Host typically does not need to know its instantaneous yaw 
angle.
Rates may also be used to enable the IG to compensate for transport delays or 
jitter produced by asynchronous operation. A Rate Control packet may be sent 
each frame in conjunction with an Entity Control packet. This provides the IG 
with enough information to extrapolate the entity's probable position during 
the next frame if necessary.

When a rate is specified for an entity or articulated part, the IG maintains 
that rate until a new rate is specified by the Host. If the Host changes the 
position and/or orientation of an entity or articulated part, the IG will 
perform the transformation and extrapolation will continue from that state 
beginning with the next frame. If the Host sets all rate components to zero, 
the entity or articulated part will become stationary.

If the entity to which a rate is applied is destroyed, any rates specified for 
that entity are annulled.

=head2 EXPORT

None by default.

#==============================================================================

=item new $rate_ctl = Rinchi::CIGIPP::RateControl->new()

Constructor for Rinchi::RateControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ac7ac-200e-11de-bda8-001c25551abc',
    '_Pack'                                => 'CCSCCSffffff',
    '_Swap1'                               => 'CCvCCvVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNN',
    'packetType'                           => 8,
    'packetSize'                           => 32,
    'entityIdent'                          => 0,
    'articulatedPartIdent'                 => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused10, coordinateSystem, and applyToArticulatedPart.
    'coordinateSystem'                     => 0,
    'applyToArticulatedPart'               => 0,
    '_unused11'                            => 0,
    'xLinearRate'                          => 0,
    'yLinearRate'                          => 0,
    'zLinearRate'                          => 0,
    'rollAngularRate'                      => 0,
    'pitchAngularRate'                     => 0,
    'yawAngularRate'                       => 0,
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

 $value = $rate_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Rate Control packet. The 
value of this attribute must be 8.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $rate_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $rate_ctl->entity_ident($newValue);

Entity ID.

This attribute specifies the entity to which the rate should be applied. If the 
Apply to Articulated Part flag is set to True (1), the rate is applied to an 
articulated part belonging to this entity. If the flag is set to False (0), the 
rate is applied to the whole entity.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub articulated_part_ident([$newValue])

 $value = $rate_ctl->articulated_part_ident($newValue);

Articulated Part ID.

This attribute specifies the articulated part to which the rate should be 
applied. If the Apply to Articulated Part flag is set to True (1), this 
attribute refers to an articulated part belonging to the entity specified by 
Entity ID. If the flag is set to False (0), this attribute is ignored.

=cut

sub articulated_part_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'articulatedPartIdent'} = $nv;
  }
  return $self->{'articulatedPartIdent'};
}

#==============================================================================

=item sub coordinate_system([$newValue])

 $value = $rate_ctl->coordinate_system($newValue);

Coordinate System.

This attribute specifies the reference coordinate system to which the linear 
and angular rates are applied.

When this attribute is set to World/Parent (0) and the entity is a top-level 
(non-child) entity, the rates are defined relative to the database. Linear 
rates describe a path along and above the surface of the geoid. Angular rates 
describe a rotation relative to a reference plane as described in Section 
3.3.1.2 of the CIGI ICD.

When this attribute is set to World/Parent (0) and the entity is a child 
entity, the rates are defined relative to the parent's local coordinate system 
as described in Section 3.3.2.2 of the CIGI ICD.

When this attribute is set to Local (1), the rates are defined relative to the 
entity's local coordinate system. Note: This attribute is ignored if Apply to 
Articulated Part is set to True (1)

    World_Parent   0
    Local          1

=cut

sub coordinate_system() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'coordinateSystem'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "coordinate_system must be 0 (World_Parent), or 1 (Local).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub apply_to_articulated_part([$newValue])

 $value = $rate_ctl->apply_to_articulated_part($newValue);

Apply to Articulated Part.

This attribute determines whether the rate is applied to the articulated part 
specified by the Articulated Part ID attribute. If this flag is set to False 
(0), the rate is applied to the entity.

    False   0
    True    1

=cut

sub apply_to_articulated_part() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'applyToArticulatedPart'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "apply_to_articulated_part must be 0 (False), or 1 (True).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub x_linear_rate([$newValue])

 $value = $rate_ctl->x_linear_rate($newValue);

X Linear Rate.

This attribute specifies the X component of a linear velocity vector.

=cut

sub x_linear_rate() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'xLinearRate'} = $nv;
  }
  return $self->{'xLinearRate'};
}

#==============================================================================

=item sub y_linear_rate([$newValue])

 $value = $rate_ctl->y_linear_rate($newValue);

Y Linear Rate.

This attribute specifies the Y component of a linear velocity vector.

=cut

sub y_linear_rate() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'yLinearRate'} = $nv;
  }
  return $self->{'yLinearRate'};
}

#==============================================================================

=item sub z_linear_rate([$newValue])

 $value = $rate_ctl->z_linear_rate($newValue);

Z Linear Rate.

This attribute specifies the Z component of a linear velocity vector.

=cut

sub z_linear_rate() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'zLinearRate'} = $nv;
  }
  return $self->{'zLinearRate'};
}

#==============================================================================

=item sub roll_angular_rate([$newValue])

 $value = $rate_ctl->roll_angular_rate($newValue);

Roll Angular Rate.

This attribute specifies the angle of rotation of the articulated part submodel 
about its X axis after yaw and pitch have been applied.

=cut

sub roll_angular_rate() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'rollAngularRate'} = $nv;
  }
  return $self->{'rollAngularRate'};
}

#==============================================================================

=item sub pitch_angular_rate([$newValue])

 $value = $rate_ctl->pitch_angular_rate($newValue);

Pitch Angular Rate.

This attribute specifies the angle of rotation of the articulated part submodel 
about its Y axis after yaw has been applied.

=cut

sub pitch_angular_rate() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'pitchAngularRate'} = $nv;
  }
  return $self->{'pitchAngularRate'};
}

#==============================================================================

=item sub yaw_angular_rate([$newValue])

 $value = $rate_ctl->yaw_angular_rate($newValue);

Yaw Angular Rate.

This attribute specifies the angle of rotation of the articulated part about 
its Z axis when its X axis is parallel to that of the entity.

=cut

sub yaw_angular_rate() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'yawAngularRate'} = $nv;
  }
  return $self->{'yawAngularRate'};
}

#==========================================================================

=item sub pack()

 $value = $rate_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'articulatedPartIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused10, coordinateSystem, and applyToArticulatedPart.
        $self->{'_unused11'},
        $self->{'xLinearRate'},
        $self->{'yLinearRate'},
        $self->{'zLinearRate'},
        $self->{'rollAngularRate'},
        $self->{'pitchAngularRate'},
        $self->{'yawAngularRate'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $rate_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'entityIdent'}                         = $c;
  $self->{'articulatedPartIdent'}                = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused10, coordinateSystem, and applyToArticulatedPart.
  $self->{'_unused11'}                           = $f;
  $self->{'xLinearRate'}                         = $g;
  $self->{'yLinearRate'}                         = $h;
  $self->{'zLinearRate'}                         = $i;
  $self->{'rollAngularRate'}                     = $j;
  $self->{'pitchAngularRate'}                    = $k;
  $self->{'yawAngularRate'}                      = $l;

  $self->{'coordinateSystem'}                    = $self->coordinate_system();
  $self->{'applyToArticulatedPart'}              = $self->apply_to_articulated_part();

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

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l);
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
