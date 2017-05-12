#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ae2d2-200e-11de-bdb2-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::MotionTrackerControl;

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

Rinchi::CIGIPP::MotionTrackerControl - Perl extension for the Common Image 
Generator Interface - Motion Tracker Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::MotionTrackerControl;
  my $mt_ctl = Rinchi::CIGIPP::MotionTrackerControl->new();

  $packet_type = $mt_ctl->packet_type();
  $packet_size = $mt_ctl->packet_size();
  $view_ident = $mt_ctl->view_ident(10606);
  $tracker_ident = $mt_ctl->tracker_ident(122);
  $yaw_enable = $mt_ctl->yaw_enable(Rinchi::CIGIPP->Enable);
  $pitch_enable = $mt_ctl->pitch_enable(Rinchi::CIGIPP->Enable);
  $roll_enable = $mt_ctl->roll_enable(Rinchi::CIGIPP->Disable);
  $z_enable = $mt_ctl->z_enable(Rinchi::CIGIPP->Enable);
  $y_enable = $mt_ctl->y_enable(Rinchi::CIGIPP->Disable);
  $x_enable = $mt_ctl->x_enable(Rinchi::CIGIPP->Enable);
  $boresight_enable = $mt_ctl->boresight_enable(Rinchi::CIGIPP->Disable);
  $tracker_enable = $mt_ctl->tracker_enable(Rinchi::CIGIPP->Disable);
  $view_group = $mt_ctl->view_group(Rinchi::CIGIPP->View);

=head1 DESCRIPTION

The Motion Tracker Control packet is used to initialize and change properties 
of tracked input devices connected to the IG. These devices may include head 
trackers, eye trackers, wands, trackballs, etc. If more than one head tracker 
is used to control a view or view group, the order in which the transformations 
are applied is determined by the IG.

The Host may request the instantaneous position and orientation of a tracker 
device by sending a Position Request packet with its Object Class attribute set 
to Motion Tracker (4).

Note that if tracked input devices are connected to the Host, the Host should 
interpret the tracked input data and send the appropriate CIGI packets to 
achieve the desired effect on the IG. For example, the Host would interpret 
input from a connected head tracker and send View Control packets to the IG to 
move the eyepoint of the appropriate view or view group.

=head2 EXPORT

None by default.

#==============================================================================

=item new $mt_ctl = Rinchi::CIGIPP::MotionTrackerControl->new()

Constructor for Rinchi::MotionTrackerControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ae2d2-200e-11de-bdb2-001c25551abc',
    '_Pack'                                => 'CCSCCCC',
    '_Swap1'                               => 'CCvCCCC',
    '_Swap2'                               => 'CCnCCCC',
    'packetType'                           => 18,
    'packetSize'                           => 8,
    'viewIdent'                            => 0,
    'trackerIdent'                         => 0,
    '_bitfields1'                          => 0, # Includes bitfields yawEnable, pitchEnable, rollEnable, zEnable, yEnable, xEnable, boresightEnable, and trackerEnable.
    'yawEnable'                            => 0,
    'pitchEnable'                          => 0,
    'rollEnable'                           => 0,
    'zEnable'                              => 0,
    'yEnable'                              => 0,
    'xEnable'                              => 0,
    'boresightEnable'                      => 0,
    'trackerEnable'                        => 0,
    '_bitfields2'                          => 0, # Includes bitfields unused32, and viewGroup.
    'viewGroup'                            => 0,
    '_unused33'                            => 0,
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

 $value = $mt_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Motion Tracker Control 
packet. The value of this attribute must be 18.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $mt_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 8.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub view_ident([$newValue])

 $value = $mt_ctl->view_ident($newValue);

View/View Group ID.

This attribute specifies the view or view group to which the tracking device is attached.

=cut

sub view_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'viewIdent'} = $nv;
  }
  return $self->{'viewIdent'};
}

#==============================================================================

=item sub tracker_ident([$newValue])

 $value = $mt_ctl->tracker_ident($newValue);

Tracker ID.

This attribute specifies the tracker whose state the data in this packet represents.

=cut

sub tracker_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'trackerIdent'} = $nv;
  }
  return $self->{'trackerIdent'};
}

#==============================================================================

=item sub yaw_enable([$newValue])

 $value = $mt_ctl->yaw_enable($newValue);

Yaw Enable.

This attribute is used to enable or disable the yaw (Z-axis rotation) of the 
motion tracker.

    Disable   0
    Enable    1

=cut

sub yaw_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'yawEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 7) &0x80;
    } else {
      carp "yaw_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x80) >> 7);
}

#==============================================================================

=item sub pitch_enable([$newValue])

 $value = $mt_ctl->pitch_enable($newValue);

Pitch Enable.

This attribute is used to enable or disable the pitch (Y-axis rotation) of the 
motion tracker.

    Disable   0
    Enable    1

=cut

sub pitch_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'pitchEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 6) &0x40;
    } else {
      carp "pitch_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x40) >> 6);
}

#==============================================================================

=item sub roll_enable([$newValue])

 $value = $mt_ctl->roll_enable($newValue);

Roll Enable.

This attribute is used to enable or disable the roll (X-axis rotation) of the 
motion tracker.

    Disable   0
    Enable    1

=cut

sub roll_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'rollEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 5) &0x20;
    } else {
      carp "roll_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x20) >> 5);
}

#==============================================================================

=item sub z_enable([$newValue])

 $value = $mt_ctl->z_enable($newValue);

Z Enable.

This attribute is used to enable or disable the Z-axis position of the motion tracker.

    Disable   0
    Enable    1

=cut

sub z_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'zEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "z_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub y_enable([$newValue])

 $value = $mt_ctl->y_enable($newValue);

Y Enable.

This attribute is used to enable or disable the Y-axis position of the motion tracker.

    Disable   0
    Enable    1

=cut

sub y_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'yEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "y_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub x_enable([$newValue])

 $value = $mt_ctl->x_enable($newValue);

X Enable.

This attribute is used to enable or disable the X-axis position of the motion tracker.

    Disable   0
    Enable    1

=cut

sub x_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'xEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "x_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub boresight_enable([$newValue])

 $value = $mt_ctl->boresight_enable($newValue);

Boresight Enable.

This attribute is used to set the boresight state of the external tracking 
device. This mode is used to reestablish the tracker's “center” position at the 
current position and orientation.

Note: If boresighting is enabled, the Host must send a Motion Tracker Control 
packet with Boresight Enable set to Disable (0) to return the tracker to normal 
operation. The IG will continue to update the boresight position each frame 
until that occurs.

    Disable   0
    Enable    1

=cut

sub boresight_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'boresightEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "boresight_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub tracker_enable([$newValue])

 $value = $mt_ctl->tracker_enable($newValue);

Tracker Enable.

This attribute specifies whether the tracking device is enabled.

    Disable   0
    Enable    1

=cut

sub tracker_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'trackerEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "tracker_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub view_group([$newValue])

 $value = $mt_ctl->view_group($newValue);

View/View Group Select.

This attribute specifies whether the tracking device is attached to a single 
view or a view group. If set to View (0), the View/View Group ID attribute 
identifies a single view. If set to View Group (1), that attribute identifies a 
view group.

    View        0
    ViewGroup   1

=cut

sub view_group() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'viewGroup'} = $nv;
      $self->{'_bitfields2'} |= $nv &0x01;
    } else {
      carp "view_group must be 0 (View), or 1 (ViewGroup).";
    }
  }
  return ($self->{'_bitfields2'} & 0x01);
}

#==========================================================================

=item sub pack()

 $value = $mt_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'viewIdent'},
        $self->{'trackerIdent'},
        $self->{'_bitfields1'},    # Includes bitfields yawEnable, pitchEnable, rollEnable, zEnable, yEnable, xEnable, boresightEnable, and trackerEnable.
        $self->{'_bitfields2'},    # Includes bitfields unused32, and viewGroup.
        $self->{'_unused33'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $mt_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'viewIdent'}                           = $c;
  $self->{'trackerIdent'}                        = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields yawEnable, pitchEnable, rollEnable, zEnable, yEnable, xEnable, boresightEnable, and trackerEnable.
  $self->{'_bitfields2'}                         = $f; # Includes bitfields unused32, and viewGroup.
  $self->{'_unused33'}                           = $g;

  $self->{'yawEnable'}                           = $self->yaw_enable();
  $self->{'pitchEnable'}                         = $self->pitch_enable();
  $self->{'rollEnable'}                          = $self->roll_enable();
  $self->{'zEnable'}                             = $self->z_enable();
  $self->{'yEnable'}                             = $self->y_enable();
  $self->{'xEnable'}                             = $self->x_enable();
  $self->{'boresightEnable'}                     = $self->boresight_enable();
  $self->{'trackerEnable'}                       = $self->tracker_enable();
  $self->{'viewGroup'}                           = $self->view_group();

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
  my ($a,$b,$c,$d,$e,$f,$g) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g);
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
