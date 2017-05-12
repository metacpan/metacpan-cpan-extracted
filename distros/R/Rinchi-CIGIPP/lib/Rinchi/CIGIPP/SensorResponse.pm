#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b28b4-200e-11de-bdcc-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SensorResponse;

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

Rinchi::CIGIPP::SensorResponse - Perl extension for the Common Image Generator 
Interface - Sensor Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SensorResponse;
  my $sensor_resp = Rinchi::CIGIPP::SensorResponse->new();

  $packet_type = $sensor_resp->packet_type();
  $packet_size = $sensor_resp->packet_size();
  $view_ident = $sensor_resp->view_ident(7825);
  $sensor_ident = $sensor_resp->sensor_ident(71);
  $sensor_status = $sensor_resp->sensor_status(Rinchi::CIGIPP->Tracking);
  $gate_xsize = $sensor_resp->gate_xsize(21687);
  $gate_ysize = $sensor_resp->gate_ysize(11524);
  $gate_xposition = $sensor_resp->gate_xposition(53.246);
  $gate_yposition = $sensor_resp->gate_yposition(75.892);
  $host_frame_number = $sensor_resp->host_frame_number(19728);

=head1 DESCRIPTION

The Sensor Response packet is used to report the gate size and position on a 
sensor display to the Host. The sensor gate size and position are defined with 
respect to the 2D view coordinate system. The +X axis is to the right of the 
screen and the +Y axis is up. The origin is at the intersection of the viewing 
vector with the view plane. The gate position is measured in degrees along each 
axis from the origin to the center of the gate.

The Gate X Position and Gate Y Position angles correspond to the horizontal and 
vertical angles formed between the sensor's viewing vector and a vector from 
the sensor eyepoint to the track point. Scaling of the sensor view can be 
performed with a View Definition packet.

The Host Frame Number attribute contains value of the Host Frame Number 
attribute of the IG Control packet last received by the IG before the gate and 
line-of-sight intersection data are calculated. The Host may correlate this 
value to an eyepoint position or may use the value to determine sensor sampling 
rate latency.

Either this packet or the Sensor Extended Response packet must be sent to the 
Host during each frame that the specified sensor is active.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sensor_resp = Rinchi::CIGIPP::SensorResponse->new()

Constructor for Rinchi::SensorResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b28b4-200e-11de-bdcc-001c25551abc',
    '_Pack'                                => 'CCSCCSSSffI',
    '_Swap1'                               => 'CCvCCvvvVVV',
    '_Swap2'                               => 'CCnCCnnnNNN',
    'packetType'                           => 106,
    'packetSize'                           => 24,
    'viewIdent'                            => 0,
    'sensorIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused74, and sensorStatus.
    'sensorStatus'                         => 0,
    '_unused75'                            => 0,
    'gateXSize'                            => 0,
    'gateYSize'                            => 0,
    'gateXPosition'                        => 0,
    'gateYPosition'                        => 0,
    'hostFrameNumber'                      => 0,
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

 $value = $sensor_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Sensor Response packet. The 
value of this attribute must be 106.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sensor_resp->packet_size();

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

 $value = $sensor_resp->view_ident($newValue);

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

 $value = $sensor_resp->sensor_ident($newValue);

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

=item sub sensor_status([$newValue])

 $value = $sensor_resp->sensor_status($newValue);

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

=item sub gate_xsize([$newValue])

 $value = $sensor_resp->gate_xsize($newValue);

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

 $value = $sensor_resp->gate_ysize($newValue);

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

 $value = $sensor_resp->gate_xposition($newValue);

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

 $value = $sensor_resp->gate_yposition($newValue);

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

 $value = $sensor_resp->host_frame_number($newValue);

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

#==========================================================================

=item sub pack()

 $value = $sensor_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'viewIdent'},
        $self->{'sensorIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused74, and sensorStatus.
        $self->{'_unused75'},
        $self->{'gateXSize'},
        $self->{'gateYSize'},
        $self->{'gateXPosition'},
        $self->{'gateYPosition'},
        $self->{'hostFrameNumber'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sensor_resp->unpack();

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
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused74, and sensorStatus.
  $self->{'_unused75'}                           = $f;
  $self->{'gateXSize'}                           = $g;
  $self->{'gateYSize'}                           = $h;
  $self->{'gateXPosition'}                       = $i;
  $self->{'gateYPosition'}                       = $j;
  $self->{'hostFrameNumber'}                     = $k;

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
