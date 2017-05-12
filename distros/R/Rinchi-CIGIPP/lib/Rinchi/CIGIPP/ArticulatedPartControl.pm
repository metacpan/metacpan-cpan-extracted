#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ac266-200e-11de-bda6-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ArticulatedPartControl;

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

Rinchi::CIGIPP::ArticulatedPartControl - Perl extension for the Common Image 
Generator Interface - Articulated Part Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ArticulatedPartControl;
  my $ap_ctl = Rinchi::CIGIPP::ArticulatedPartControl->new();

  $packet_type = $ap_ctl->packet_type();
  $packet_size = $ap_ctl->packet_size();
  $entity_ident = $ap_ctl->entity_ident(63243);
  $articulated_part_ident = $ap_ctl->articulated_part_ident(6);
  $yaw_enable = $ap_ctl->yaw_enable(Rinchi::CIGIPP->Disable);
  $pitch_enable = $ap_ctl->pitch_enable(Rinchi::CIGIPP->Enable);
  $roll_enable = $ap_ctl->roll_enable(Rinchi::CIGIPP->Enable);
  $z_offset_enable = $ap_ctl->z_offset_enable(Rinchi::CIGIPP->Disable);
  $y_offset_enable = $ap_ctl->y_offset_enable(Rinchi::CIGIPP->Enable);
  $x_offset_enable = $ap_ctl->x_offset_enable(Rinchi::CIGIPP->Disable);
  $articulated_part_enable = $ap_ctl->articulated_part_enable(Rinchi::CIGIPP->Enable);
  $x_offset = $ap_ctl->x_offset(3.419);
  $y_offset = $ap_ctl->y_offset(55.33);
  $z_offset = $ap_ctl->z_offset(80.089);
  $roll = $ap_ctl->roll(2.203);
  $pitch = $ap_ctl->pitch(81.151);
  $yaw = $ap_ctl->yaw(61.683);

=head1 DESCRIPTION

Articulated parts are entity features that can be rotated and/or translated 
with respect to the entity. These features are submodels of the entity model 
and possess their own coordinate systems. Examples include wing flaps, landing 
gear, and tank turrets.

Articulated parts may be manipulated in up to six degrees of freedom. 
Translation is defined as X, Y, and Z offsets relative to the submodel's 
reference point. Rotation is defined relative to the submodel coordinate 
system.
Positional and rotational values are not cumulative. They are absolute values 
relative to the coordinate system defined within the model.

=head2 EXPORT

None by default.

#==============================================================================

=item new $ap_ctl = Rinchi::CIGIPP::ArticulatedPartControl->new()

Constructor for Rinchi::ArticulatedPartControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ac266-200e-11de-bda6-001c25551abc',
    '_Pack'                                => 'CCSCCSffffff',
    '_Swap1'                               => 'CCvCCSVVVVVV',
    '_Swap2'                               => 'CCnCCSNNNNNN',
    'packetType'                           => 6,
    'packetSize'                           => 32,
    'entityIdent'                          => 0,
    'articulatedPartIdent'                 => 0,
    '_bitfields1'                          => 0, # Includes bitfields yawEnable, pitchEnable, rollEnable, zOffsetEnable, yOffsetEnable, xOffsetEnable, and articulatedPartEnable.
    'yawEnable'                            => 0,
    'pitchEnable'                          => 0,
    'rollEnable'                           => 0,
    'zOffsetEnable'                        => 0,
    'yOffsetEnable'                        => 0,
    'xOffsetEnable'                        => 0,
    'articulatedPartEnable'                => 0,
    '_unused8'                             => 0,
    'xOffset'                              => 0,
    'yOffset'                              => 0,
    'zOffset'                              => 0,
    'roll'                                 => 0,
    'pitch'                                => 0,
    'yaw'                                  => 0,
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

 $value = $ap_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Articulated Part Control 
packet. The value of this attribute must be 6.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $ap_ctl->packet_size();

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

 $value = $ap_ctl->entity_ident($newValue);

Entity ID.

This attribute specifies the entity to which the articulated part belongs.

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

 $value = $ap_ctl->articulated_part_ident($newValue);

Articulated Part ID.

This attribute specifies the articulated part to which the data in this packet 
should be applied. When used with the Entity ID attribute, this attribute 
uniquely identifies a particular articulated part within the simulation.

=cut

sub articulated_part_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'articulatedPartIdent'} = $nv;
  }
  return $self->{'articulatedPartIdent'};
}

#==============================================================================

=item sub yaw_enable([$newValue])

 $value = $ap_ctl->yaw_enable($newValue);

Yaw Enable.

This attribute determines whether the Yaw attribute of the current packet 
should be applied to the articulated part. If this attribute is set to Disable 
(0), Yaw is ignored and the articulated part retains its current yaw angle.

    Disable   0
    Enable    1

=cut

sub yaw_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'yawEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 6) &0x40;
    } else {
      carp "yaw_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x40) >> 6);
}

#==============================================================================

=item sub pitch_enable([$newValue])

 $value = $ap_ctl->pitch_enable($newValue);

Pitch Enable.

This attribute determines whether the Pitch attribute of the current packet 
should be applied to the articulated part. If this attribute is set to Disable 
(0), Pitch is ignored and the articulated part retains its current pitch angle.

    Disable   0
    Enable    1

=cut

sub pitch_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'pitchEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 5) &0x20;
    } else {
      carp "pitch_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x20) >> 5);
}

#==============================================================================

=item sub roll_enable([$newValue])

 $value = $ap_ctl->roll_enable($newValue);

Roll Enable.

This attribute determines whether the Roll attribute of the current packet 
should be applied to the articulated part. If this attribute is set to Disable 
(0), Roll is ignored and the articulated part retains its current roll angle.

    Disable   0
    Enable    1

=cut

sub roll_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'rollEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "roll_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub z_offset_enable([$newValue])

 $value = $ap_ctl->z_offset_enable($newValue);

Z Offset Enable.

This attribute determines whether the Z Offset attribute of the current packet 
should be applied to the articulated part. If this attribute is set to Disable 
(0), Z Offset is ignored and the articulated part remains at its current 
location along the submodel's Z axis.

    Disable   0
    Enable    1

=cut

sub z_offset_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'zOffsetEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "z_offset_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub y_offset_enable([$newValue])

 $value = $ap_ctl->y_offset_enable($newValue);

Y Offset Enable.

This attribute determines whether the Y Offset attribute of the current packet 
should be applied to the articulated part. If this attribute is set to Disable 
(0), Y Offset is ignored and the articulated part remains at its current 
location along the submodel's Y axis.

    Disable   0
    Enable    1

=cut

sub y_offset_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'yOffsetEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "y_offset_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub x_offset_enable([$newValue])

 $value = $ap_ctl->x_offset_enable($newValue);

X Offset Enable.

This attribute determines whether the X Offset attribute of the current packet 
should be applied to the articulated part. If this attribute is set to Disable 
(0), X Offset is ignored and the articulated part remains at its current 
location along the submodel's X axis.

    Disable   0
    Enable    1

=cut

sub x_offset_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'xOffsetEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "x_offset_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub articulated_part_enable([$newValue])

 $value = $ap_ctl->articulated_part_enable($newValue);

Articulated Part Enable.

This attribute determines whether the articulated part submodel should be 
enabled or disabled within the scene graph. If this attribute is set to Disable 
(0), the part is removed from the scene; if the attribute is set to Enable (1), 
the part is included in the scene.

    Disable   0
    Enable    1

=cut

sub articulated_part_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'articulatedPartEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "articulated_part_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub x_offset([$newValue])

 $value = $ap_ctl->x_offset($newValue);

X Offset.

This attribute represents the distance in meters from the submodel reference 
point to the articulated part along its X axis.

=cut

sub x_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'xOffset'} = $nv;
  }
  return $self->{'xOffset'};
}

#==============================================================================

=item sub y_offset([$newValue])

 $value = $ap_ctl->y_offset($newValue);

Y Offset.

This attribute represents the distance in meters from the submodel reference 
point to the articulated part along its Y axis.

=cut

sub y_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'yOffset'} = $nv;
  }
  return $self->{'yOffset'};
}

#==============================================================================

=item sub z_offset([$newValue])

 $value = $ap_ctl->z_offset($newValue);

Z Offset.

This attribute represents the distance in meters from the submodel reference 
point to the articulated part along its Z axis.

=cut

sub z_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'zOffset'} = $nv;
  }
  return $self->{'zOffset'};
}

#==============================================================================

=item sub roll([$newValue])

 $value = $ap_ctl->roll($newValue);

Roll.

This attribute specifies the angle of rotation measured in degrees relative to 
the submodel coordinate system of the articulated part submodel about its X 
axis after yaw and pitch have been applied.

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

 $value = $ap_ctl->pitch($newValue);

Pitch.

This attribute specifies the angle of rotation measured in degrees relative to 
the submodel coordinate system of the articulated part submodel about its Y 
axis after yaw has been applied.

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

 $value = $ap_ctl->yaw($newValue);

Yaw.

This attribute specifies the angle of rotation measured in degrees relative to 
the submodel coordinate system of the articulated part about its Z axis.

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

 $value = $ap_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'articulatedPartIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused8, yawEnable, pitchEnable, rollEnable, zOffsetEnable, yOffsetEnable, xOffsetEnable, and articulatedPartEnable.
        $self->{'_unused8'},
        $self->{'xOffset'},
        $self->{'yOffset'},
        $self->{'zOffset'},
        $self->{'roll'},
        $self->{'pitch'},
        $self->{'yaw'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ap_ctl->unpack();

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
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused8, yawEnable, pitchEnable, rollEnable, zOffsetEnable, yOffsetEnable, xOffsetEnable, and articulatedPartEnable.
  $self->{'_unused8'}                            = $f;
  $self->{'xOffset'}                             = $g;
  $self->{'yOffset'}                             = $h;
  $self->{'zOffset'}                             = $i;
  $self->{'roll'}                                = $j;
  $self->{'pitch'}                               = $k;
  $self->{'yaw'}                                 = $l;

  $self->{'yawEnable'}                           = $self->yaw_enable();
  $self->{'pitchEnable'}                         = $self->pitch_enable();
  $self->{'rollEnable'}                          = $self->roll_enable();
  $self->{'zOffsetEnable'}                       = $self->z_offset_enable();
  $self->{'yOffsetEnable'}                       = $self->y_offset_enable();
  $self->{'xOffsetEnable'}                       = $self->x_offset_enable();
  $self->{'articulatedPartEnable'}               = $self->articulated_part_enable();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k);
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
