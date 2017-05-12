#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b30ac-200e-11de-bdcf-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::WeatherConditionsResponse;

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

Rinchi::CIGIPP::WeatherConditionsResponse - Perl extension for the Common Image 
Generator Interface - Weather Conditions Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::WeatherConditionsResponse;
  my $wthr_resp = Rinchi::CIGIPP::WeatherConditionsResponse->new();

  $packet_type = $wthr_resp->packet_type();
  $packet_size = $wthr_resp->packet_size();
  $request_ident = $wthr_resp->request_ident(41);
  $humidity = $wthr_resp->humidity(45);
  $air_temperature = $wthr_resp->air_temperature(76.992);
  $visibility_range = $wthr_resp->visibility_range(36.303);
  $horizontal_wind_speed = $wthr_resp->horizontal_wind_speed(47.571);
  $vertical_wind_speed = $wthr_resp->vertical_wind_speed(45.084);
  $wind_direction = $wthr_resp->wind_direction(0.137);
  $barometric_pressure = $wthr_resp->barometric_pressure(89.194);

=head1 DESCRIPTION

The Weather Conditions Response packet is sent in response to an Environmental 
Conditions Request packet whose Request Type attribute specifies Weather 
Conditions. The packet describes atmosphere properties at the requested 
geodetic position.

=head2 EXPORT

None by default.

#==============================================================================

=item new $wthr_resp = Rinchi::CIGIPP::WeatherConditionsResponse->new()

Constructor for Rinchi::WeatherConditionsResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b30ac-200e-11de-bdcf-001c25551abc',
    '_Pack'                                => 'CCCCffffffI',
    '_Swap1'                               => 'CCCCVVVVVVV',
    '_Swap2'                               => 'CCCCNNNNNNN',
    'packetType'                           => 109,
    'packetSize'                           => 32,
    'requestIdent'                         => 0,
    'humidity'                             => 0,
    'airTemperature'                       => 0,
    'visibilityRange'                      => 0,
    'horizontalWindSpeed'                  => 0,
    'verticalWindSpeed'                    => 0,
    'windDirection'                        => 0,
    'barometricPressure'                   => 0,
    '_unused80'                            => 0,
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

 $value = $wthr_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Weather Conditions Response 
packet. The value of this attribute must be 109.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $wthr_resp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $wthr_resp->request_ident($newValue);

Request ID.

This attribute identifies the environmental conditions request to which this 
response packet corresponds.

=cut

sub request_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'requestIdent'} = $nv;
  }
  return $self->{'requestIdent'};
}

#==============================================================================

=item sub humidity([$newValue])

 $value = $wthr_resp->humidity($newValue);

Humidity.

This attribute indicates the humidity at the requested location.

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

 $value = $wthr_resp->air_temperature($newValue);

Air Temperature.

This attribute indicates the air temperature, measured in degrees Celcius, at 
the requested location.

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

 $value = $wthr_resp->visibility_range($newValue);

Visibility Range.

This attribute indicates the visibility range, measured in meters, at the 
requested location.

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

 $value = $wthr_resp->horizontal_wind_speed($newValue);

Horizontal Wind Speed.

This attribute indicates the local wind speed, measured in meters/second, 
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

 $value = $wthr_resp->vertical_wind_speed($newValue);

Vertical Wind Speed.

This attribute indicates the local vertical wind speed, measured in 
meters/second.
Note: A positive value indicates an updraft, while a negative value indicates a downdraft.

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

 $value = $wthr_resp->wind_direction($newValue);

Wind Direction.

This attribute indicates the local wind direction.

Note: This is the direction from which the wind is blowing.

Datum: True North

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

 $value = $wthr_resp->barometric_pressure($newValue);

Barometric Pressure.

This attribute indicates the atmospheric pressure at the requested location.

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

 $value = $wthr_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'humidity'},
        $self->{'airTemperature'},
        $self->{'visibilityRange'},
        $self->{'horizontalWindSpeed'},
        $self->{'verticalWindSpeed'},
        $self->{'windDirection'},
        $self->{'barometricPressure'},
        $self->{'_unused80'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $wthr_resp->unpack();

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
  $self->{'requestIdent'}                        = $c;
  $self->{'humidity'}                            = $d;
  $self->{'airTemperature'}                      = $e;
  $self->{'visibilityRange'}                     = $f;
  $self->{'horizontalWindSpeed'}                 = $g;
  $self->{'verticalWindSpeed'}                   = $h;
  $self->{'windDirection'}                       = $i;
  $self->{'barometricPressure'}                  = $j;
  $self->{'_unused80'}                           = $k;

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
