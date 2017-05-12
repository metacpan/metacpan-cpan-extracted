#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ad2ec-200e-11de-bdac-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::WeatherControl;

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

Rinchi::CIGIPP::WeatherControl - Perl extension for the Common Image Generator 
Interface - Weather Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::WeatherControl;
  my $wthr_ctl = Rinchi::CIGIPP::WeatherControl->new();

  $packet_type = $wthr_ctl->packet_type();
  $packet_size = $wthr_ctl->packet_size();
  $entity_ident = $wthr_ctl->entity_ident(22740);
  $region_ident = $wthr_ctl->region_ident(59769);
  $layer_ident = $wthr_ctl->layer_ident(131);
  $humidity = $wthr_ctl->humidity(89);
  $cloud_type = $wthr_ctl->cloud_type(Rinchi::CIGIPP->None);
  $random_lightning_enable = $wthr_ctl->random_lightning_enable(Rinchi::CIGIPP->Disable);
  $random_winds_enable = $wthr_ctl->random_winds_enable(Rinchi::CIGIPP->Disable);
  $scud_enable = $wthr_ctl->scud_enable(Rinchi::CIGIPP->Enable);
  $weather_enable = $wthr_ctl->weather_enable(Rinchi::CIGIPP->Enable);
  $severity = $wthr_ctl->severity(2);
  $weather_scope = $wthr_ctl->weather_scope(Rinchi::CIGIPP->RegionalScope);
  $air_temperature = $wthr_ctl->air_temperature(15.426);
  $visibility_range = $wthr_ctl->visibility_range(89.817);
  $scud_frequency = $wthr_ctl->scud_frequency(2.31);
  $coverage = $wthr_ctl->coverage(84.412);
  $base_elevation = $wthr_ctl->base_elevation(47.967);
  $thickness = $wthr_ctl->thickness(38.301);
  $transition_band = $wthr_ctl->transition_band(70.407);
  $horizontal_wind_speed = $wthr_ctl->horizontal_wind_speed(45.598);
  $vertical_wind_speed = $wthr_ctl->vertical_wind_speed(85.529);
  $wind_direction = $wthr_ctl->wind_direction(62.819);
  $barometric_pressure = $wthr_ctl->barometric_pressure(82.459);
  $aerosol_concentration = $wthr_ctl->aerosol_concentration(3.569);

=head1 DESCRIPTION

The Weather Control packet is used to control weather layers and weather 
entities. Global weather layers have no distinct horizontal boundaries. 
Atmospheric affects can be observed anywhere within the vertical range of the 
layer. Regional weather layers occur only in areas defined by the Environmental 
Region Control packet (CIGI ICD Section 4.1.11). Weather entities are entities 
that represent meteorological phenomena.

The Layer ID attribute specifies the global or regional weather layer whose 
attributes are being set. If the Scope attribute is set to Global (0), the 
weather layer exists everywhere over the database. If this attribute is set to 
Region (1), the weather layer is bound to the region specified by the Region ID 
attribute. Up to 256 weather layers may be defined globally, and up to 256 
layers may be defined within each region. The Layer ID attribute is ignored for 
weather entities.

The Cloud Type attribute specifies the type of cloud found within a cloud layer 
or entity. Each value may correspond to a specific cloud texture or model. 
Values one through 10 are reserved for the most common general cloud types as 
listed in Table 18. The remaining values can be used for mammatus clouds, 
Kelvin-Helmholtz cloud effects, and other specific cloud phenomena.

The vertical range of a weather layer is specified by the Base Elevation, 
Thickness, and Transition Band attributes. Base Elevation specifies the 
distance from Mean Sea Level to the bottom of the layer. Thickness is the 
vertical height of the layer. Transition Band specifies the vertical height of 
both the region above and below the layer through which visibility gradually 
changes from that of the layer to that immediately outside the region.

For weather entities, the Transition Band attribute can be used to specify a 
threshold radius for partial penetration into a cloud model. The Base Elevation 
and Thickness attributes are ignored for weather entities.

The Scud Enable attribute specifies whether the layer produces scud effects 
within the transition band. The Scud Frequency attribute defines how often scud 
occurs. The placement of scud (i.e., above versus below the layer) depends upon 
the IG implementation. Some systems allow this to be controlled via a Component 
Control packet.

The Horizontal Wind Speed, Vertical Wind Speed, and Wind Direction attributes 
define the wind velocity within the weather layer or entity. These can be used 
to specify surface winds or winds aloft, depending upon the base elevation and 
thickness of the layer or the altitude of the weather entity. The Random Winds 
Enable attribute causes the IG to create gusts of random duration and 
frequency.
A typical effect of weather layers is the suspension of liquid or solid 
particles in the air. The density of this particulate matter is specified by 
the Aerosol Concentration attribute. The most common aerosol is liquid water, 
but ice crystals, sand, and dust are also common. Weather layers may also be 
used to create smoke, combat haze, and other man-made airborne contaminants. 
Each layer can contain zero or one type of mutable aerosol; multiple aerosols 
in a given space must be implemented as separate weather layers.

Where weather layers overlap, atmospheric effects should be combined as as 
described in the CIGI ICD.

=head2 EXPORT

None by default.

#==============================================================================

=item new $wthr_ctl = Rinchi::CIGIPP::WeatherControl->new()

Constructor for Rinchi::WeatherControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ad2ec-200e-11de-bdac-001c25551abc',
    '_Pack'                                => 'CCSCCCCffffffffffff',
    '_Swap1'                               => 'CCvCCCCVVVVVVVVVVVV',
    '_Swap2'                               => 'CCnCCCCNNNNNNNNNNNN',
    'packetType'                           => 12,
    'packetSize'                           => 56,
    'regionEntityIdent'                    => 0,
    'layerIdent'                           => 0,
    'humidity'                             => 0,
    '_bitfields1'                          => 0, # Includes bitfields cloudType, randomLightningEnable, randomWindsEnable, scudEnable, and weatherEnable.
    'cloudType'                            => 0,
    'randomLightningEnable'                => 0,
    'randomWindsEnable'                    => 0,
    'scudEnable'                           => 0,
    'weatherEnable'                        => 0,
    '_bitfields2'                          => 0, # Includes bitfields unused21, severity, and weatherScope.
    'severity'                             => 0,
    'weatherScope'                         => 0,
    'airTemperature'                       => 0,
    'visibilityRange'                      => 0,
    'scudFrequency'                        => 0,
    'coverage'                             => 0,
    'baseElevation'                        => 0,
    'thickness'                            => 0,
    'transitionBand'                       => 0,
    'horizontalWindSpeed'                  => 0,
    'verticalWindSpeed'                    => 0,
    'windDirection'                        => 0,
    'barometricPressure'                   => 0,
    'aerosolConcentration'                 => 0,
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

 $value = $wthr_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Weather Control packet. The 
value of this attribute must be 12.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $wthr_ctl->packet_size();

Data Packet Size. 

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 56.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $wthr_ctl->entity_ident($newValue);

Entity ID.           (Weather Entities)

This attribute specifies the entity to which the weather attributes in this 
packet are applied.

Note: Entity ID/Region ID is ignored if Scope is set to Global (0).

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub region_ident([$newValue])

 $value = $wthr_ctl->region_ident($newValue);

Region ID.

This attribute specifies the region to which the weather layer is confined.

Note: Entity ID/Region ID is ignored if Scope is set to Global (0).

=cut

sub region_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'regionIdent'} = $nv;
  }
  return $self->{'regionIdent'};
}

#==============================================================================

=item sub layer_ident([$newValue])

 $value = $wthr_ctl->layer_ident($newValue);

Layer ID.

This attribute specifies the weather layer to which the data in this packet are 
applied. This attribute also determines the type of aerosol contained within 
the layer.

Values 0 through 9 are defined as standard weather  layer types. Values beyond 
this range are defined in the IG configuration.

Note: This attribute is ignored if Scope is set to Entity (2).

=cut

sub layer_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'layerIdent'} = $nv;
  }
  return $self->{'layerIdent'};
}

#==============================================================================

=item sub humidity([$newValue])

 $value = $wthr_ctl->humidity($newValue);

Humidity.

This attribute specifies the humidity, measured in percent, within the weather layer/entity.

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

=item sub cloud_type([$newValue])

 $value = $wthr_ctl->cloud_type($newValue);

Cloud Type.

This attribute specifies the type of clouds contained within the weather layer. 
If the value of Layer ID does not correspond to a cloud layer, Cloud Type 
should be set to None (0).

    None            0
    Altocumulus     1
    Altostratus     2
    Cirrocumulus    3
    Cirrostratus    4
    Cirrus          5
    Cumulonimbus    6
    Cumulus         7
    Nimbostratus    8
    Stratocumulus   9
    Stratus         10
    Other1          11
    Other2          12
    Other3          13
    Other4          14
    Other5          15

=cut

sub cloud_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv>=0 and $nv<=15 and int($nv) == $nv) {
      $self->{'cloudType'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0xF0;
    } else {
      carp "cloud_type must be 0 (None), 1 (Altocumulus), 2 (Altostratus), 3 (Cirrocumulus), 4 (Cirrostratus), 5 (Cirrus), 6 (Cumulonimbus), 7 (Cumulus), 8 (Nimbostratus), 9 (Stratocumulus), 10 (Stratus), 11 (Other1), 12 (Other2), 13 (Other3), 14 (Other4), or 15 (Other5).";
    }
  }
  return (($self->{'_bitfields1'} & 0xF0) >> 4);
}

#==============================================================================

=item sub random_lightning_enable([$newValue])

 $value = $wthr_ctl->random_lightning_enable($newValue);

Random Lightning Enable.

This attribute specifies whether the weather layer or entity exhibits random 
lightning effects. The frequency and severity of the lightning varies according 
to the Severity attribute.

    Disable   0
    Enable    1

=cut

sub random_lightning_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'randomLightningEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "random_lightning_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub random_winds_enable([$newValue])

 $value = $wthr_ctl->random_winds_enable($newValue);

Random Winds Enable.

This attribute specifies whether a random frequency and duration should be 
applied to the local wind effects.

    Disable   0
    Enable    1

=cut

sub random_winds_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'randomWindsEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "random_winds_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub scud_enable([$newValue])

 $value = $wthr_ctl->scud_enable($newValue);

Scud Enable

This attribute specifies whether weather layer produces scud effects within its 
transition bands.

    Disable   0
    Enable    1

=cut

sub scud_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'scudEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "scud_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub weather_enable([$newValue])

 $value = $wthr_ctl->weather_enable($newValue);

Weather Enable.

This attribute specifies whether a weather layer/entity and its atmospheric 
effects are enabled.

    Disable   0
    Enable    1

=cut

sub weather_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'weatherEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "weather_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub severity([$newValue])

 $value = $wthr_ctl->severity($newValue);

Severity.

This attribute specifies the severity of the weather layer/entity.

=cut

sub severity() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv>=0 and $nv<=5 and int($nv)==$nv) {
      $self->{'severity'} = $nv;
      $self->{'_bitfields2'} |= ($nv << 3) &0x18;
    } else {
      carp "severity must be an integer 0-5.";
    }
  }
  return (($self->{'_bitfields2'} & 0x18) >> 3);
}

#==============================================================================

=item sub weather_scope([$newValue])

 $value = $wthr_ctl->weather_scope($newValue);

Weather Scope.

This attribute specifies whether the weather is global, regional, or assigned 
to an entity. If this value is set to Regional (1), the layer is confined to 
the region specified by Region ID. If this value is set to Entity (2), the 
weather attributes are applied to the volume within the moving model specified 
by Entity ID.

    GlobalScope     0
    RegionalScope   1
    EntityScope     2

=cut

sub weather_scope() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'weatherScope'} = $nv;
      $self->{'_bitfields2'} |= $nv &0x07;
    } else {
      carp "weather_scope must be 0 (GlobalScope), 1 (RegionalScope), or 2 (EntityScope).";
    }
  }
  return ($self->{'_bitfields2'} & 0x07);
}

#==============================================================================

=item sub air_temperature([$newValue])

 $value = $wthr_ctl->air_temperature($newValue);

Air Temperature.

This attribute specifies the temperature, measered in degrees Celsius (°C), 
within the weather layer/entity.

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

 $value = $wthr_ctl->visibility_range($newValue);

Visibility Range.

This attribute specifies the visibility range, measured in meters, through the 
weather layer/entity. This might correspond to Runway Visibility Range through 
ground fog, for example.

=cut

sub visibility_range() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'visibilityRange'} = $nv;
  }
  return $self->{'visibilityRange'};
}

#==============================================================================

=item sub scud_frequency([$newValue])

 $value = $wthr_ctl->scud_frequency($newValue);

Scud Frequency.

This attribute specifies the frequency of scud within the transition bands 
above and/or below a cloud or fog layer. A value of 0% produces no scud effect; 
100% produces a solid effect.

=cut

sub scud_frequency() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'scudFrequency'} = $nv;
  }
  return $self->{'scudFrequency'};
}

#==============================================================================

=item sub coverage([$newValue])

 $value = $wthr_ctl->coverage($newValue);

Coverage.

This attribute specifies the amount of area coverage for the weather layer.

=cut

sub coverage() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'coverage'} = $nv;
  }
  return $self->{'coverage'};
}

#==============================================================================

=item sub base_elevation([$newValue])

 $value = $wthr_ctl->base_elevation($newValue);

Base Elevation.

This attribute specifies the altitude of the base (bottom) of the weather 
layer. This attribute is ignored if Scope is set to Entity (2).

=cut

sub base_elevation() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'baseElevation'} = $nv;
  }
  return $self->{'baseElevation'};
}

#==============================================================================

=item sub thickness([$newValue])

 $value = $wthr_ctl->thickness($newValue);

Thickness.

This attribute specifies the vertical thickness of the weather layer. The 
altitude of the top of the layer is equal to this value plus that specified by 
Base Elevation. This attribute is ignored if Scope is set to Entity (2).

=cut

sub thickness() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'thickness'} = $nv;
  }
  return $self->{'thickness'};
}

#==============================================================================

=item sub transition_band([$newValue])

 $value = $wthr_ctl->transition_band($newValue);

Transition Band.

This attribute specifies the height of a vertical transition band both above 
and below the weather layer. This band produces a visibility gradient from the 
layer's visibility to that immediately outside the transition band. This 
attribute is ignored if Scope is set to Entity (2).

=cut

sub transition_band() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'transitionBand'} = $nv;
  }
  return $self->{'transitionBand'};
}

#==============================================================================

=item sub horizontal_wind_speed([$newValue])

 $value = $wthr_ctl->horizontal_wind_speed($newValue);

Horizontal Wind Speed.

This attribute specifies the local wind speed parallel to the 
ellipsoid-tangential reference plane.

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

 $value = $wthr_ctl->vertical_wind_speed($newValue);

Vertical Wind Speed.

This attribute specifies the local vertical wind speed.

Note: A positive value produces an updraft, while a negative value produces a downdraft.

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

 $value = $wthr_ctl->wind_direction($newValue);

Wind Direction.

This attribute specifies the local wind direction.

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

 $value = $wthr_ctl->barometric_pressure($newValue);

Barometric Pressure.

This attribute specifies the atmospheric pressure, measured in millibars (mb) 
or hectopascals (hPa), within the weather layer or entity. The units are interchangeable.

=cut

sub barometric_pressure() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'barometricPressure'} = $nv;
  }
  return $self->{'barometricPressure'};
}

#==============================================================================

=item sub aerosol_concentration([$newValue])

 $value = $wthr_ctl->aerosol_concentration($newValue);

Aerosol Concentration.

This attribute specifies the concentration of water, smoke, dust, or other 
particles suspended in the air.

This attribute is provided primarily for sensor applications; any visual effect 
is secondary and is IG- and layer-dependent.

Note: The type of aerosol depends upon the layer ID of a weather layer, or the 
entity type of a weather phenomenon entity.

=cut

sub aerosol_concentration() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'aerosolConcentration'} = $nv;
  }
  return $self->{'aerosolConcentration'};
}

#==========================================================================

=item sub pack()

 $value = $wthr_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'regionEntityIdent'},
        $self->{'layerIdent'},
        $self->{'humidity'},
        $self->{'_bitfields1'},    # Includes bitfields cloudType, randomLightningEnable, randomWindsEnable, scudEnable, and weatherEnable.
        $self->{'_bitfields2'},    # Includes bitfields unused21, severity, and WthrScope.
        $self->{'airTemperature'},
        $self->{'visibilityRange'},
        $self->{'scudFrequency'},
        $self->{'coverage'},
        $self->{'baseElevation'},
        $self->{'thickness'},
        $self->{'transitionBand'},
        $self->{'horizontalWindSpeed'},
        $self->{'verticalWindSpeed'},
        $self->{'windDirection'},
        $self->{'barometricPressure'},
        $self->{'aerosolConcentration'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $wthr_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'regionEntityIdent'}                   = $c;
  $self->{'layerIdent'}                          = $d;
  $self->{'humidity'}                            = $e;
  $self->{'_bitfields1'}                         = $f; # Includes bitfields cloudType, randomLightningEnable, randomWindsEnable, scudEnable, and weatherEnable.
  $self->{'_bitfields2'}                         = $g; # Includes bitfields unused21, severity, and WthrScope.
  $self->{'airTemperature'}                      = $h;
  $self->{'visibilityRange'}                     = $i;
  $self->{'scudFrequency'}                       = $j;
  $self->{'coverage'}                            = $k;
  $self->{'baseElevation'}                       = $l;
  $self->{'thickness'}                           = $m;
  $self->{'transitionBand'}                      = $n;
  $self->{'horizontalWindSpeed'}                 = $o;
  $self->{'verticalWindSpeed'}                   = $p;
  $self->{'windDirection'}                       = $q;
  $self->{'barometricPressure'}                  = $r;
  $self->{'aerosolConcentration'}                = $s;

  $self->{'cloudType'}                           = $self->cloud_type();
  $self->{'randomLightningEnable'}               = $self->random_lightning_enable();
  $self->{'randomWindsEnable'}                   = $self->random_winds_enable();
  $self->{'scudEnable'}                          = $self->scud_enable();
  $self->{'weatherEnable'}                       = $self->weather_enable();
  $self->{'severity'}                            = $self->severity();
  $self->{'weatherScope'}                        = $self->weather_scope();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s);
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
