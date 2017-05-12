#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b2b5c-200e-11de-bdcd-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SensorExtendedResponse;

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

Rinchi::CIGIPP::SensorExtendedResponse - Perl extension for the Common Image 
Generator Interface - Sensor Extended Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SensorExtendedResponse;
  my $sensor_xresp = Rinchi::CIGIPP::SensorExtendedResponse->new();

  $packet_type = $sensor_xresp->packet_type();
  $packet_size = $sensor_xresp->packet_size();
  $view_ident = $sensor_xresp->view_ident(15496);
  $sensor_ident = $sensor_xresp->sensor_ident(37242);
  $entity_ident_valid = $sensor_xresp->entity_ident_valid(Rinchi::CIGIPP->Valid);
  $sensor_status = $sensor_xresp->sensor_status(Rinchi::CIGIPP->Searching);
  $entity_ident = $sensor_xresp->entity_ident(64212);
  $gate_xsize = $sensor_xresp->gate_xsize(22491);
  $gate_ysize = $sensor_xresp->gate_ysize(15321);
  $gate_xposition = $sensor_xresp->gate_xposition(9.495);
  $gate_yposition = $sensor_xresp->gate_yposition(56.78);
  $host_frame_number = $sensor_xresp->host_frame_number(22764);
  $track_point_latitude = $sensor_xresp->track_point_latitude(75.221);
  $track_point_longitude = $sensor_xresp->track_point_longitude(4.123);
  $track_point_altitude = $sensor_xresp->track_point_altitude(68.142);

=head1 DESCRIPTION

The Sensor Extended Response packet, like the Sensor Response packet, is used 
to report the gate size and position on a sensor display to the Host. This 
packet also contains the geodetic position of the sensor track point and the 
entity ID of the target.

Either this packet or the Sensor Response packet must be sent to the Host 
during each frame that the specified sensor is active.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sensor_xresp = Rinchi::CIGIPP::SensorExtendedResponse->new()

Constructor for Rinchi::SensorExtendedResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b2b5c-200e-11de-bdcd-001c25551abc',
    '_Pack'                                => 'CCSCCSSSffIddd',
    '_Swap1'                               => 'CCvCCvvvVVVVVVVVV',
    '_Swap2'                               => 'CCnCCnnnNNNNNNNNN',
    'packetType'                           => 107,
    'packetSize'                           => 48,
    'viewIdent'                            => 0,
    'sensorIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused76, entityIdentValid, and sensorStatus.
    'entityIdentValid'                     => 0,
    'sensorStatus'                         => 0,
    'entityIdent'                          => 0,
    'gateXSize'                            => 0,
    'gateYSize'                            => 0,
    'gateXPosition'                        => 0,
    'gateYPosition'                        => 0,
    'hostFrameNumber'                      => 0,
    'trackPointLatitude'                   => 0,
    'trackPointLongitude'                  => 0,
    'trackPointAltitude'                   => 0,
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

 $value = $sensor_xresp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Sensor Extended Response 
packet. The value of this attribute must be 107.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sensor_xresp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 48.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub view_ident([$newValue])

 $value = $sensor_xresp->view_ident($newValue);

View ID.

This attribute specifies the view that represents the sensor display.

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

 $value = $sensor_xresp->sensor_ident($newValue);

Sensor ID.

This attribute specifies the sensor to which the data in this packet apply.

=cut

sub sensor_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sensorIdent'} = $nv;
  }
  return $self->{'sensorIdent'};
}

#==============================================================================

=item sub entity_ident_valid([$newValue])

 $value = $sensor_xresp->entity_ident_valid($newValue);

Entity ID Valid.

This attribute indicates whether the target is an entity or a non-entity 
object. If this attribute is set to Valid (1), then Entity ID identifies the 
target entity.

    Invalid   0
    Valid     1

=cut

sub entity_ident_valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'entityIdentValid'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "entity_ident_valid must be 0 (Invalid), or 1 (Valid).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub sensor_status([$newValue])

 $value = $sensor_xresp->sensor_status($newValue);

Sensor Status.

This attribute indicates the current tracking state of the sensor.

    Searching            0
    Tracking             1
    ImpendingBreaklock   2
    Breaklock            3

=cut

sub sensor_status() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3)) {
      $self->{'sensorStatus'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x03;
    } else {
      carp "sensor_status must be 0 (Searching), 1 (Tracking), 2 (ImpendingBreaklock), or 3 (Breaklock).";
    }
  }
  return ($self->{'_bitfields1'} & 0x03);
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $sensor_xresp->entity_ident($newValue);

Entity ID.

This attribute indicates the entity ID of the target. This attribute is ignored 
if Entity ID Valid is set to Invalid (0).

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub gate_xsize([$newValue])

 $value = $sensor_xresp->gate_xsize($newValue);

Gate X Size.

This attribute specifies the gate symbol size along the view's X axis.

Note: This size is specified in either pixels or raster lines depending upon 
the orientation of the display.

=cut

sub gate_xsize() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'gateXSize'} = $nv;
  }
  return $self->{'gateXSize'};
}

#==============================================================================

=item sub gate_ysize([$newValue])

 $value = $sensor_xresp->gate_ysize($newValue);

Gate Y Size.

This attribute specifies the gate symbol size along the view's Y axis.

Note: This size is specified in either pixels or raster lines depending upon 
the orientation of the display.

=cut

sub gate_ysize() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'gateYSize'} = $nv;
  }
  return $self->{'gateYSize'};
}

#==============================================================================

=item sub gate_xposition([$newValue])

 $value = $sensor_xresp->gate_xposition($newValue);

Gate X Position.

This attribute specifies the gate symbol's position along the view's X axis. 
This position is given as the horizontal angle formed at the sensor eyepoint 
between the sensor's viewing vector and the center of the track point.

=cut

sub gate_xposition() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'gateXPosition'} = $nv;
  }
  return $self->{'gateXPosition'};
}

#==============================================================================

=item sub gate_yposition([$newValue])

 $value = $sensor_xresp->gate_yposition($newValue);

Gate Y Position.

This attribute specifies the gate symbol's position along the view's Y axis. 
This position is given as the vertical angle formed at the sensor eyepoint 
between the sensor's viewing vector and the center of the track point.

=cut

sub gate_yposition() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'gateYPosition'} = $nv;
  }
  return $self->{'gateYPosition'};
}

#==============================================================================

=item sub host_frame_number([$newValue])

 $value = $sensor_xresp->host_frame_number($newValue);

Host Frame Number.

This attribute indicates the Host frame number at the time that the IG 
calculates the gate and line-of-sight intersection data.

=cut

sub host_frame_number() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'hostFrameNumber'} = $nv;
  }
  return $self->{'hostFrameNumber'};
}

#==============================================================================

=item sub track_point_latitude([$newValue])

 $value = $sensor_xresp->track_point_latitude($newValue);

Track Point Latitude.

This attribute indicates the geodetic latitude of the point being tracked by 
the sensor. This attribute is valid only when the Sensor Status attribute is 
set to one (1) or two (2).

=cut

sub track_point_latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-90) and ($nv<=90.0)) {
      $self->{'trackPointLatitude'} = $nv;
    } else {
      carp "track_point_latitude must be from -90.0 to +90.0.";
    }
  }
  return $self->{'trackPointLatitude'};
}

#==============================================================================

=item sub track_point_longitude([$newValue])

 $value = $sensor_xresp->track_point_longitude($newValue);

Track Point Longitude.

This attribute indicates the geodetic longitude of the  point being tracked by 
the sensor. This attribute is valid only when the Sensor Status attribute is 
set to one (1) or two (2).

=cut

sub track_point_longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-180.0) and ($nv<=180.0)) {
      $self->{'trackPointLongitude'} = $nv;
    } else {
      carp "track_point_longitude must be from -180.0 to +180.0.";
    }
  }
  return $self->{'trackPointLongitude'};
}

#==============================================================================

=item sub track_point_altitude([$newValue])

 $value = $sensor_xresp->track_point_altitude($newValue);

Track Point Altitude.

This attribute indicates the geodetic altitude of the point being tracked by 
the sensor measured in meters above mean sea level. This attribute is valid 
only when the Sensor Status attribute is set to one (1) or two (2).

=cut

sub track_point_altitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'trackPointAltitude'} = $nv;
  }
  return $self->{'trackPointAltitude'};
}

#==========================================================================

=item sub pack()

 $value = $sensor_xresp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'viewIdent'},
        $self->{'sensorIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused76, entityIdentValid, and sensorStatus.
        $self->{'entityIdent'},
        $self->{'gateXSize'},
        $self->{'gateYSize'},
        $self->{'gateXPosition'},
        $self->{'gateYPosition'},
        $self->{'hostFrameNumber'},
        $self->{'trackPointLatitude'},
        $self->{'trackPointLongitude'},
        $self->{'trackPointAltitude'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sensor_xresp->unpack();

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
  $self->{'viewIdent'}                           = $c;
  $self->{'sensorIdent'}                         = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused76, entityIdentValid, and sensorStatus.
  $self->{'entityIdent'}                         = $f;
  $self->{'gateXSize'}                           = $g;
  $self->{'gateYSize'}                           = $h;
  $self->{'gateXPosition'}                       = $i;
  $self->{'gateYPosition'}                       = $j;
  $self->{'hostFrameNumber'}                     = $k;
  $self->{'trackPointLatitude'}                  = $l;
  $self->{'trackPointLongitude'}                 = $m;
  $self->{'trackPointAltitude'}                  = $n;

  $self->{'entityIdentValid'}                    = $self->entity_ident_valid();
  $self->{'sensorStatus'}                        = $self->sensor_status();

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
     $self->unpack();
  }
#    '_Pack'                                => 'CCSCCSSSffIddd',
#    '_Swap1'                               => 'CCvvCvvvVVVVVVVVV',
#    '_Swap2'                               => 'CCnnCnnnNNNNNNNNN',
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$m,$l,$o,$n,$q,$p);
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
