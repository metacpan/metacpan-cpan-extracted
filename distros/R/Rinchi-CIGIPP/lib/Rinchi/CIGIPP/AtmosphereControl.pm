#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78acd92-200e-11de-bdaa-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::AtmosphereControl;

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

Rinchi::CIGIPP::AtmosphereControl - Perl extension for the Common Image 
Generator Interface - Atmosphere Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::AtmosphereControl;
  my $atmos_ctl = Rinchi::CIGIPP::AtmosphereControl->new();

  $packet_type = $atmos_ctl->packet_type();
  $packet_size = $atmos_ctl->packet_size();
  $atmospheric_model_enable = $atmos_ctl->atmospheric_model_enable(Rinchi::CIGIPP->Disable);
  $humidity = $atmos_ctl->humidity(35);
  $air_temperature = $atmos_ctl->air_temperature(23.357);
  $visibility_range = $atmos_ctl->visibility_range(47.803);
  $horizontal_wind_speed = $atmos_ctl->horizontal_wind_speed(55.727);
  $vertical_wind_speed = $atmos_ctl->vertical_wind_speed(40.386);
  $wind_direction = $atmos_ctl->wind_direction(47.212);
  $barometric_pressure = $atmos_ctl->barometric_pressure(17.871);

=head1 DESCRIPTION

The Atmosphere Control data packet allows the Host to control global 
atmospheric properties within the simulation.

Weather layers and weather entities always take precedence over the global 
atmospheric conditions. Once the atmospheric properties of a layer or entity 
are set, global atmospheric changes will not affect the weather inside the 
layer or entity unless that layer or entity is disabled. The global atmospheric 
changes will, however, affect the weather within a transition band or 
transition perimeter.

CIGI supports the use of FASCODE, MODTRAN, SEDRIS, or other atmospheric models 
for determining radiance and transmittance within a heterogeneous atmosphere 
for sensor simulations. The Atmospheric Model Enable attribute determines 
whether an atmospheric model is used. The particular model is not specified and 
is determined by the IG.

=head2 EXPORT

None by default.

#==============================================================================

=item new $atmos_ctl = Rinchi::CIGIPP::AtmosphereControl->new()

Constructor for Rinchi::AtmosphereControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78acd92-200e-11de-bdaa-001c25551abc',
    '_Pack'                                => 'CCCCffffffI',
    '_Swap1'                               => 'CCCCVVVVVVV',
    '_Swap2'                               => 'CCCCNNNNNNN',
    'packetType'                           => 10,
    'packetSize'                           => 32,
    '_bitfields1'                          => 0, # Includes bitfields unused15, and atmosphericModelEnable.
    'atmosphericModelEnable'               => 0,
    'humidity'                             => 0,
    'airTemperature'                       => 0,
    'visibilityRange'                      => 0,
    'horizontalWindSpeed'                  => 0,
    'verticalWindSpeed'                    => 0,
    'windDirection'                        => 0,
    'barometricPressure'                   => 0,
    '_unused16'                            => 0,
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

 $value = $atmos_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Atmosphere Control packet. 
The value of this attribute must be 10.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $atmos_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub atmospheric_model_enable([$newValue])

 $value = $atmos_ctl->atmospheric_model_enable($newValue);

Atmospheric Model Enable.

This attribute specifies whether the IG should use an atmospheric model to 
determine spectral radiances for sensor applications. If this attribute is set 
to Disable (0), source radiances will be calculated. If this  attribute is set 
to Enable (1), apparent radiances will be calculated using the appropriate models.

    Disable   0
    Enable    1

=cut

sub atmospheric_model_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'atmosphericModelEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "atmospheric_model_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub humidity([$newValue])

 $value = $atmos_ctl->humidity($newValue);

Global Humidity.

This attribute specifies the global humidity of the environment.

=cut

sub humidity() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv>=0 and $nv<=100 and int($nv)==$nv) {
      $self->{'humidity'} = $nv;
    } else {
      carp "humidity must be an integer 0-100 (percent).";
    }
  }
  return $self->{'humidity'};
}

#==============================================================================

=item sub air_temperature([$newValue])

 $value = $atmos_ctl->air_temperature($newValue);

Global Air Temperature.

This attribute specifies the global air temperature of the environment.

=cut

sub air_temperature() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'airTemperature'} = $nv;
  }
  return $self->{'airTemperature'};
}

#==============================================================================

=item sub visibility_range([$newValue])

 $value = $atmos_ctl->visibility_range($newValue);

Global Visibility Range.

This attribute specifies the global visibility range through the atmosphere 
measured in meters.

=cut

sub visibility_range() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'visibilityRange'} = $nv;
  }
  return $self->{'visibilityRange'};
}

#==============================================================================

=item sub horizontal_wind_speed([$newValue])

 $value = $atmos_ctl->horizontal_wind_speed($newValue);

Global Horizontal Wind Speed.

This attribute specifies the global wind speed, measured in meters/second, 
parallel to the ellipsoid-tangential reference plane.

=cut

sub horizontal_wind_speed() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'horizontalWindSpeed'} = $nv;
  }
  return $self->{'horizontalWindSpeed'};
}

#==============================================================================

=item sub vertical_wind_speed([$newValue])

 $value = $atmos_ctl->vertical_wind_speed($newValue);

Global Vertical Wind Speed.

This attribute specifies the global vertical wind speed measured in 
meters/second. A positive value produces an updraft, while a negative value 
produces a downdraft.

=cut

sub vertical_wind_speed() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'verticalWindSpeed'} = $nv;
  }
  return $self->{'verticalWindSpeed'};
}

#==============================================================================

=item sub wind_direction([$newValue])

 $value = $atmos_ctl->wind_direction($newValue);

Global Wind Direction.

This attribute specifies the global wind direction.

Note: This is the direction from which the wind is blowing.

=cut

sub wind_direction() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'windDirection'} = $nv;
  }
  return $self->{'windDirection'};
}

#==============================================================================

=item sub barometric_pressure([$newValue])

 $value = $atmos_ctl->barometric_pressure($newValue);

Global Barometric Pressure.

This attribute specifies the global atmospheric pressure measured in millibars 
(mb) or hectopascals (hPa). The units are interchangeable.

=cut

sub barometric_pressure() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'barometricPressure'} = $nv;
  }
  return $self->{'barometricPressure'};
}

#==========================================================================

=item sub pack()

 $value = $atmos_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'_bitfields1'},    # Includes bitfields unused15, and atmosphericModelEnable.
        $self->{'humidity'},
        $self->{'airTemperature'},
        $self->{'visibilityRange'},
        $self->{'horizontalWindSpeed'},
        $self->{'verticalWindSpeed'},
        $self->{'windDirection'},
        $self->{'barometricPressure'},
        $self->{'_unused16'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack([$buffer])

 $value = $atmos_ctl->unpack($buffer);

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
  $self->{'_bitfields1'}                         = $c; # Includes bitfields unused15, and atmosphericModelEnable.
  $self->{'humidity'}                            = $d;
  $self->{'airTemperature'}                      = $e;
  $self->{'visibilityRange'}                     = $f;
  $self->{'horizontalWindSpeed'}                 = $g;
  $self->{'verticalWindSpeed'}                   = $h;
  $self->{'windDirection'}                       = $i;
  $self->{'barometricPressure'}                  = $j;
  $self->{'_unused16'}                           = $k;
  $self->{'atmosphericModelEnable'}              = $self->atmospheric_model_enable();

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub byte_swap()

 $value = $atmos_ctl->byte_swap();

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

#==========================================================================

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
