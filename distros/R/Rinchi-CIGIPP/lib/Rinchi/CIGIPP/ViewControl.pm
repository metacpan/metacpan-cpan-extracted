#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78add82-200e-11de-bdb0-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ViewControl;

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

Rinchi::CIGIPP::ViewControl - Perl extension for the Common Image Generator 
Interface - View Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ViewControl;
  my $view_ctl = Rinchi::CIGIPP::ViewControl->new();

  $packet_type = $view_ctl->packet_type();
  $packet_size = $view_ctl->packet_size();
  $view_ident = $view_ctl->view_ident(11410);
  $group_ident = $view_ctl->group_ident(132);
  $yaw_enable = $view_ctl->yaw_enable(Rinchi::CIGIPP->Enable);
  $pitch_enable = $view_ctl->pitch_enable(Rinchi::CIGIPP->Enable);
  $roll_enable = $view_ctl->roll_enable(Rinchi::CIGIPP->Enable);
  $z_offset_enable = $view_ctl->z_offset_enable(Rinchi::CIGIPP->Disable);
  $y_offset_enable = $view_ctl->y_offset_enable(Rinchi::CIGIPP->Enable);
  $x_offset_enable = $view_ctl->x_offset_enable(Rinchi::CIGIPP->Disable);
  $entity_ident = $view_ctl->entity_ident(22744);
  $x_offset = $view_ctl->x_offset(14.225);
  $y_offset = $view_ctl->y_offset(68.843);
  $z_offset = $view_ctl->z_offset(19.148);
  $roll = $view_ctl->roll(53.063);
  $pitch = $view_ctl->pitch(75.147);
  $yaw = $view_ctl->yaw(45.894);

=head1 DESCRIPTION

The View Control packet is used to attach a view or view group to an entity and 
to define the position and rotation of the view relative to the entity's 
reference point. Views can be positioned to correspond to the pilot eye, 
weapon/sensor viewpoints, and stealth view cameras.

Multiple views may be combined to form one or more view groups. This allows 
more than one view to be moved in unison with a single View Control packet. A 
view group is identified by the Group ID attribute. Operations performed upon a 
view group affect all views in that group. If Group ID is set to zero (0), the 
packet is applied to an individual view, identified by the View ID attribute.

The order of operation for views and view groups is the same as that for 
entities. A view is first translated along the entity's X, Y, and Z axes. After 
it is translated, the view is rotated about the eyepoint. The order of rotation 
is first about Z axis (yaw), then the Y axis (pitch), and finally the X axis (roll).

=head2 EXPORT

None by default.

#==============================================================================

=item new $view_ctl = Rinchi::CIGIPP::ViewControl->new()

Constructor for Rinchi::ViewControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78add82-200e-11de-bdb0-001c25551abc',
    '_Pack'                                => 'CCSCCSffffff',
    '_Swap1'                               => 'CCvCCvVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNN',
    'packetType'                           => 16,
    'packetSize'                           => 32,
    'viewIdent'                            => 0,
    'groupIdent'                           => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused28, yawEnable, pitchEnable, rollEnable, zOffsetEnable, yOffsetEnable, and xOffsetEnable.
    'yawEnable'                            => 0,
    'pitchEnable'                          => 0,
    'rollEnable'                           => 0,
    'zOffsetEnable'                        => 0,
    'yOffsetEnable'                        => 0,
    'xOffsetEnable'                        => 0,
    'entityIdent'                          => 0,
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

 $value = $view_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the View Control packet. The 
value of this attribute must  be 16.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $view_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub view_ident([$newValue])

 $value = $view_ctl->view_ident($newValue);

View ID.

This attribute specifies the view to which the contents of this packet should 
be applied. This value is ignored if the Group ID attribute contains a non-zero value.

=cut

sub view_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'viewIdent'} = $nv;
  }
  return $self->{'viewIdent'};
}

#==============================================================================

=item sub group_ident([$newValue])

 $value = $view_ctl->group_ident($newValue);

Group ID.

This attribute specifies the view group to which the contents of this packet 
are applied. If this value is zero (0), the packet is applied to the individual 
view specified by the View ID attribute. If this value is non-zero, the packet 
is applied to the specified view group and the View ID attribute is ignored.

=cut

sub group_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'groupIdent'} = $nv;
  }
  return $self->{'groupIdent'};
}

#==============================================================================

=item sub yaw_enable([$newValue])

 $value = $view_ctl->yaw_enable($newValue);

Yaw Enable.

This attribute determines whether the Yaw attribute should be applied to the 
specified view or view group. If this flag is set to Disable (0), the Yaw 
attribute is ignored.

    Disable   0
    Enable    1

=cut

sub yaw_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'yawEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 5) &0x20;
    } else {
      carp "yaw_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x20) >> 5);
}

#==============================================================================

=item sub pitch_enable([$newValue])

 $value = $view_ctl->pitch_enable($newValue);

Pitch Enable.

This attribute determines whether the Pitch attribute should be applied to the 
specified view or view group. If this flag is set to Disable (0), the Pitch 
attribute is ignored.

    Disable   0
    Enable    1

=cut

sub pitch_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'pitchEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "pitch_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub roll_enable([$newValue])

 $value = $view_ctl->roll_enable($newValue);

Roll Enable.

This attribute determines whether the Roll attribute should be applied to the 
specified view or view group. If this flag is set to Disable (0), the Roll 
attribute is ignored.

    Disable   0
    Enable    1

=cut

sub roll_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'rollEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "roll_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub z_offset_enable([$newValue])

 $value = $view_ctl->z_offset_enable($newValue);

Z Offset Enable.

This attribute determines whether the Z Offset attribute should be applied to 
the specified view or view group. If this flag is set to Disable (0), the Z 
Offset attribute is ignored.

    Disable   0
    Enable    1

=cut

sub z_offset_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'zOffsetEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "z_offset_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub y_offset_enable([$newValue])

 $value = $view_ctl->y_offset_enable($newValue);

Y Offset Enable.

This attribute determines whether the Y Offset attribute should be applied to 
the specified view or view group. If this flag is set to Disable (0), the Y 
Offset attribute is ignored.

    Disable   0
    Enable    1

=cut

sub y_offset_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'yOffsetEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "y_offset_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub x_offset_enable([$newValue])

 $value = $view_ctl->x_offset_enable($newValue);

X Offset Enable.

This attribute determines whether the X Offset attribute should be applied to 
the specified view or view group. If this flag is set to Disable (0), the X 
Offset attribute is ignored.

    Disable   0
    Enable    1

=cut

sub x_offset_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'xOffsetEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "x_offset_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $view_ctl->entity_ident($newValue);

Entity ID.

This attribute specifies the entity to which the view or view group should be attached.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub x_offset([$newValue])

 $value = $view_ctl->x_offset($newValue);

X Offset.

This attribute specifies the position of the view eyepoint along the X axis of 
the entity specified by the Entity ID attribute.

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

 $value = $view_ctl->y_offset($newValue);

Y Offset.

This attribute specifies the position of the view eyepoint along the Y axis of 
the entity specified by the Entity ID attribute.

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

 $value = $view_ctl->z_offset($newValue);

Z Offset.

This attribute specifies the position of the view eyepoint along the Z axis of 
the entity specified by the Entity ID attribute.

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

 $value = $view_ctl->roll($newValue);

Roll.

This attribute specifies the angle of rotation of the view or view group about 
its X axis after yaw and pitch have been applied.

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

 $value = $view_ctl->pitch($newValue);

Pitch.

This attribute specifies the angle of rotation of the view or view group about 
its Y axis after yaw has been applied.

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

 $value = $view_ctl->yaw($newValue);

Yaw.

This attribute specifies the angle of rotation of the view or view group about 
its Z axis.

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

 $value = $view_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'viewIdent'},
        $self->{'groupIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused28, yawEnable, pitchEnable, rollEnable, zOffsetEnable, yOffsetEnable, and xOffsetEnable.
        $self->{'entityIdent'},
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

 $value = $view_ctl->unpack();

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
  $self->{'viewIdent'}                           = $c;
  $self->{'groupIdent'}                          = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused28, yawEnable, pitchEnable, rollEnable, zOffsetEnable, yOffsetEnable, and xOffsetEnable.
  $self->{'entityIdent'}                         = $f;
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
