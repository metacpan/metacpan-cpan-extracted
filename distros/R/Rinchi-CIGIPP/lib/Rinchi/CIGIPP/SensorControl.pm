#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ae02a-200e-11de-bdb1-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SensorControl;

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

Rinchi::CIGIPP::SensorControl - Perl extension for the Common Image Generator 
Interface - Sensor Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SensorControl;
  my $sensor_ctl = Rinchi::CIGIPP::SensorControl->new();

  $packet_type = $sensor_ctl->packet_type();
  $packet_size = $sensor_ctl->packet_size();
  $view_ident = $sensor_ctl->view_ident(53486);
  $sensor_ident = $sensor_ctl->sensor_ident(190);
  $track_mode = $sensor_ctl->track_mode(Rinchi::CIGIPP->Off);
  $track_white_black = $sensor_ctl->track_white_black(Rinchi::CIGIPP->Black);
  $automatic_gain_enable = $sensor_ctl->automatic_gain_enable(Rinchi::CIGIPP->Enable);
  $line_by_line_dropout_enable = $sensor_ctl->line_by_line_dropout_enable(Rinchi::CIGIPP->Enable);
  $polarity = $sensor_ctl->polarity(Rinchi::CIGIPP->WhiteHot);
  $sensor_on_off = $sensor_ctl->sensor_on_off(Rinchi::CIGIPP->Off);
  $response_type = $sensor_ctl->response_type(Rinchi::CIGIPP->ExtendedSRT);
  $gain = $sensor_ctl->gain(62.89);
  $level = $sensor_ctl->level(54.416);
  $ac_coupling = $sensor_ctl->ac_coupling(61.664);
  $noise = $sensor_ctl->noise(42.664);

=head1 DESCRIPTION

The Sensor Control packet is used to control sensor modes and display behavior 
for sensor-based weapons systems and other sensor applications. It is typically 
used in conjunction the View Control packet, which moves the sensor camera 
eyepoint. The View Definition and Component Control packets can also be used to 
control various aspects of camera and sensor behavior.

A sensor is associated with a view through the View ID attribute. A sensor may 
be associated with more than one view to allow the sensor imagery to be 
displayed on multiple displays; however, this may evoke multiple Sensor 
Response or Sensor Extended Response packets from the IG.

In a typical scenario, the sensor will be inactive until the user turns the 
sensor on. The Host will send a Sensor Control packet with the Sensor On/Off 
attribute set to On (1). Because the sensor is not yet tracking a target, the 
Track Mode attribute of this packet should be set to Off (0). The Host might 
also send a View Control packet to make sure the initial sensor camera position 
is set. Additional View Control packets will be sent as the user slews the 
sensor view.

When the user attempts to lock onto a target, the Host will send a Sensor 
Control packet, setting the Track Mode attribute to the appropriate value. 
Because the Host will need the position of the track point to determine which 
entity is the target, it sets the Response Type attribute to Gate and Target 
Position (1).

The IG will immediately begin sending response packets (in this case, Sensor 
Extended Response packets) that contain the gate symbol position and, if 
appropriate, the sensor target position. A response packet will be sent every 
frame until the IG is directed to do otherwise by the Host.

The Sensor Status attribute of the response packets will indicate whether the 
sensor was able to establish a lock. If the sensor was unable to do so, the 
Sensor Status attribute will be set to zero (0). The Host then should reset the 
Track Mode attribute to Off (0) before the user again tries to lock onto the 
target. If, on the other hand, the lock was successful, then the Sensor Status 
attribute will be set to one (1).

The Entity ID attribute of the Sensor Extended Response packet contains the ID 
of the target entity. If the IG cannot determine the target, or if the sensor 
is tracking non-entity geometry, then the Entity ID Valid attribute of the 
response packet will be set to Invalid (0). The Host must then use the target 
position returned by the IG to determine which entity or object is being 
tracked by the sensor. This may occur immediately or over several frames, 
depending upon the number and proximity of entities along the sensor viewing 
vector.
Once the Host has determined the target, it can send a Sensor Control packet 
with its Response Type attribute set to Gate Position (1), directing the IG to 
send Sensor Response packets instead of Sensor Extended Response packets.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sensor_ctl = Rinchi::CIGIPP::SensorControl->new()

Constructor for Rinchi::SensorControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ae02a-200e-11de-bdb1-001c25551abc',
    '_Pack'                                => 'CCSCCCCffff',
    '_Swap1'                               => 'CCvCCCCVVVV',
    '_Swap2'                               => 'CCnCCCCNNNN',
    'packetType'                           => 17,
    'packetSize'                           => 24,
    'viewIdent'                            => 0,
    'sensorIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields trackMode, TrackWhtBlk, automaticGainEnable, lineByLineDropoutEnable, polarity, and sensorOnOff.
    'trackMode'                            => 0,
    'trackWhiteBlack'                      => 0,
    'automaticGainEnable'                  => 0,
    'lineByLineDropoutEnable'              => 0,
    'polarity'                             => 0,
    'sensorOnOff'                          => 0,
    '_bitfields2'                          => 0, # Includes bitfields unused30, and responseType.
    'responseType'                         => 0,
    '_unused31'                            => 0,
    'gain'                                 => 0,
    'level'                                => 0,
    'acCoupling'                           => 0,
    'noise'                                => 0,
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

 $value = $sensor_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Sensor Control packet. The 
value of this attribute must be 17.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sensor_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 24.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub view_ident([$newValue])

 $value = $sensor_ctl->view_ident($newValue);

View ID.

This attribute identifies the view to which the specified sensor is assigned. 
Note that a sensor cannot be assigned to a view group.

=cut

sub view_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'viewIdent'} = $nv;
  }
  return $self->{'viewIdent'};
}

#==============================================================================

=item sub sensor_ident([$newValue])

 $value = $sensor_ctl->sensor_ident($newValue);

Sensor ID.

This attribute specifies the sensor to which the data in this packet are applied.

=cut

sub sensor_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sensorIdent'} = $nv;
  }
  return $self->{'sensorIdent'};
}

#==============================================================================

=item sub track_mode([$newValue])

 $value = $sensor_ctl->track_mode($newValue);

Track Mode.

This attribute specifies which track mode the sensor should use:

Off – No tracking will occur.

Force Correlate – The sensor processes a portion of the view image, establishes 
an image pattern, and attempts to keep the seeker pointed at the center of that 
image pattern. This mode is typically used for Maverick sensors.

Scene – The sensor processes a portion of the view image, establishes an image 
pattern, and attempts to keep the seeker pointed at the center of that image 
pattern. This mode is typically used for FLIR sensors.

Target – The sensor uses contrast tracking to lock to a specific target area.

Ship – The sensor uses contrast tracking and adjusts the tracking point so that 
the weapon strikes close to the water line.

    Off              0
    ForceCorrelate   1
    Scene            2
    Target           3
    Ship             4
    IGDefined3       5
    IGDefined2       6
    IGDefined1       7

=cut

sub track_mode() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6) or ($nv==7)) {
      $self->{'trackMode'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 5) &0xE0;
    } else {
      carp "track_mode must be 0 (Off), 1 (ForceCorrelate), 2 (Scene), 3 (Target), 4 (Ship), 5 (IGDefined3), 6 (IGDefined2), or 7 (IGDefined1).";
    }
  }
  return (($self->{'_bitfields1'} & 0xE0) >> 5);
}

#==============================================================================

=item sub track_white_black([$newValue])

 $value = $sensor_ctl->track_white_black($newValue);

Track White/Black.

This attribute specifies whether the sensor tracks white (0) or black (1). 
This, along with the Polarity attribute, controls whether the sensor tracks hot 
or cold spots.

    White   0
    Black   1

=cut

sub track_white_black() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'trackWhiteBlack'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "track_white_black must be 0 (White), or 1 (Black).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub automatic_gain_enable([$newValue])

 $value = $sensor_ctl->automatic_gain_enable($newValue);

Automatic Gain.

This attribute specifies whether the sensor automatically adjusts the gain 
value to optimize the brightness and contrast of the sensor display.

    Disable   0
    Enable    1

=cut

sub automatic_gain_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'automaticGainEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "automatic_gain_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub line_by_line_dropout_enable([$newValue])

 $value = $sensor_ctl->line_by_line_dropout_enable($newValue);

Line-by-Line Dropout Enable.

This attribute specifies whether line-by-line dropout is enabled.

    Disable   0
    Enable    1

=cut

sub line_by_line_dropout_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'lineByLineDropoutEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "line_by_line_dropout_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub polarity([$newValue])

 $value = $sensor_ctl->polarity($newValue);

Polarity.

This attribute specifies whether the sensor shows white hot (0) or black hot (1).

    WhiteHot   0
    BlackHot   1

=cut

sub polarity() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'polarity'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "polarity must be 0 (WhiteHot), or 1 (BlackHot).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub sensor_on_off([$newValue])

 $value = $sensor_ctl->sensor_on_off($newValue);

Sensor On/Off.

This attribute specifies whether the sensor is turned on or off.

    Off   0
    On    1

=cut

sub sensor_on_off() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'sensorOnOff'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "sensor_on_off must be 0 (Off), or 1 (On).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub response_type([$newValue])

 $value = $sensor_ctl->response_type($newValue);

Response Type.

This attribute specifies whether the IG should return a Sensor Response packet 
or a Sensor Extended Response packet.

    NormalSRT     0
    ExtendedSRT   1

=cut

sub response_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'responseType'} = $nv;
      $self->{'_bitfields2'} |= $nv &0x01;
    } else {
      carp "response_type must be 0 (NormalSRT), or 1 (ExtendedSRT).";
    }
  }
  return ($self->{'_bitfields2'} & 0x01);
}

#==============================================================================

=item sub gain([$newValue])

 $value = $sensor_ctl->gain($newValue);

Gain.

This attribute specifies the contrast for the sensor display.

=cut

sub gain() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'gain'} = $nv;
  }
  return $self->{'gain'};
}

#==============================================================================

=item sub level([$newValue])

 $value = $sensor_ctl->level($newValue);

Level.

This attribute specifies the brightness for the sensor display.

=cut

sub level() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'level'} = $nv;
  }
  return $self->{'level'};
}

#==============================================================================

=item sub ac_coupling([$newValue])

 $value = $sensor_ctl->ac_coupling($newValue);

AC Coupling.

This attribute specifies the AC coupling decay constant for the sensor display.

=cut

sub ac_coupling() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'acCoupling'} = $nv;
  }
  return $self->{'acCoupling'};
}

#==============================================================================

=item sub noise([$newValue])

 $value = $sensor_ctl->noise($newValue);

Noise.

This attribute specifies the amount of detector noise for the sensor.

=cut

sub noise() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'noise'} = $nv;
  }
  return $self->{'noise'};
}

#==========================================================================

=item sub pack()

 $value = $sensor_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'viewIdent'},
        $self->{'sensorIdent'},
        $self->{'_bitfields1'},    # Includes bitfields trackMode, TrackWhtBlk, automaticGainEnable, lineByLineDropoutEnable, polarity, and sensorOnOff.
        $self->{'_bitfields2'},    # Includes bitfields unused30, and responseType.
        $self->{'_unused31'},
        $self->{'gain'},
        $self->{'level'},
        $self->{'acCoupling'},
        $self->{'noise'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sensor_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'viewIdent'}                           = $c;
  $self->{'sensorIdent'}                         = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields trackMode, TrackWhtBlk, automaticGainEnable, lineByLineDropoutEnable, polarity, and sensorOnOff.
  $self->{'_bitfields2'}                         = $f; # Includes bitfields unused30, and responseType.
  $self->{'_unused31'}                           = $g;
  $self->{'gain'}                                = $h;
  $self->{'level'}                               = $i;
  $self->{'acCoupling'}                          = $j;
  $self->{'noise'}                               = $k;

  $self->{'trackMode'}                           = $self->track_mode();
  $self->{'trackWhiteBlack'}                     = $self->track_white_black();
  $self->{'automaticGainEnable'}                 = $self->automatic_gain_enable();
  $self->{'lineByLineDropoutEnable'}             = $self->line_by_line_dropout_enable();
  $self->{'polarity'}                            = $self->polarity();
  $self->{'sensorOnOff'}                         = $self->sensor_on_off();
  $self->{'responseType'}                        = $self->response_type();

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
