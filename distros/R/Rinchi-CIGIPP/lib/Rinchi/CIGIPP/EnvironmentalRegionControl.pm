#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ad044-200e-11de-bdab-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::EnvironmentalRegionControl;

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

Rinchi::CIGIPP::EnvironmentalRegionControl - Perl extension for the Common 
Image Generator Interface - Environmental Region Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::EnvironmentalRegionControl;
  my $env_ctl = Rinchi::CIGIPP::EnvironmentalRegionControl->new();

  $packet_type = $env_ctl->packet_type();
  $packet_size = $env_ctl->packet_size();
  $region_ident = $env_ctl->region_ident(20814);
  $merge_terrestrial_surface_conditions = $env_ctl->merge_terrestrial_surface_conditions(Rinchi::CIGIPP->Merge);
  $merge_maritime_surface_conditions = $env_ctl->merge_maritime_surface_conditions(Rinchi::CIGIPP->UseLast);
  $merge_aerosol_concentrations = $env_ctl->merge_aerosol_concentrations(Rinchi::CIGIPP->Merge);
  $merge_weather_properties = $env_ctl->merge_weather_properties(Rinchi::CIGIPP->UseLast);
  $region_state = $env_ctl->region_state(Rinchi::CIGIPP->Active);
  $latitude = $env_ctl->latitude(59.996);
  $longitude = $env_ctl->longitude(81.934);
  $size_x = $env_ctl->size_x(35.271);
  $size_y = $env_ctl->size_y(24.1);
  $corner_radius = $env_ctl->corner_radius(47.747);
  $rotation = $env_ctl->rotation(71.893);
  $transition_perimeter = $env_ctl->transition_perimeter(3.385);

=head1 DESCRIPTION

The Environmental Region Control packet is used to define an area over which 
the atmospheric conditions and maritime and terrestrial surface conditions can 
be specified. The shape of the region is a rounded rectangle. 

Up to 256 weather layers may be defined within a region. Weather layers can be 
created and manipulated with the Weather Control packet. One set of maritime 
and/or terrestrial surface condition attributes may be defined per region.

The Host is responsible for updating the position and shape of each region. The 
IG does not automatically manipulate regions because of wind activity or any 
other internal or external forces.

The center of the region is defined by the Latitude and Longitude attributes. 
The origin of the region's local coordinate system is at this point. The Size X 
and Size Y attributes determine the length of the rounded rectangle along its X 
and Y axes.

The "roundness" of the corners is determined by the Corner Radius attribute. 
Setting this radius to zero (0) will create a rectangle. Setting the value 
equal to one-half that of Size X and Size Y when both are equal will create a 
circle. The corner radius must be less than or equal to one half of the smaller 
of Size X or Size Y.

The Rotation attribute specifies an angle of rotation (clockwise) about the Z 
axis of the local NED coordinate system.

=head2 EXPORT

None by default.

#==============================================================================

=item new $env_ctl = Rinchi::CIGIPP::EnvironmentalRegionControl->new()

Constructor for Rinchi::EnvironmentalRegionControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ad044-200e-11de-bdab-001c25551abc',
    '_Pack'                                => 'CCSCCSddfffffI',
    '_Swap1'                               => 'CCvCCvVVVVVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNNNNNN',
    'packetType'                           => 11,
    'packetSize'                           => 48,
    'regionIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused17, mergeTerrestrialSurfaceConditions, mergeMaritimeSurfaceConditions, mergeAerosolConcentrations, mergeWeatherProperties, and regionState.
    'mergeTerrestrialSurfaceConditions'    => 0,
    'mergeMaritimeSurfaceConditions'       => 0,
    'mergeAerosolConcentrations'           => 0,
    'mergeWeatherProperties'               => 0,
    'regionState'                          => 0,
    '_unused18'                            => 0,
    '_unused19'                            => 0,
    'latitude'                             => 0,
    'longitude'                            => 0,
    'sizeX'                                => 0,
    'sizeY'                                => 0,
    'cornerRadius'                         => 0,
    'rotation'                             => 0,
    'transitionPerimeter'                  => 0,
    '_unused20'                            => 0,
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

 $value = $env_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Environmental Region Control 
packet. The value of this attribute must be 11.

=cut

sub packet_type() {
  my ($self) = @_;

  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $env_ctl->packet_size();

Data Packet Size. 

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 48.

=cut

sub packet_size() {
  my ($self) = @_;

  return $self->{'packetSize'};
}

#==============================================================================

=item sub region_ident([$newValue])

 $value = $env_ctl->region_ident($newValue);

Region ID.

This attribute specifies the environmental region to which the data in this 
packet will be applied.

=cut

sub region_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'regionIdent'} = $nv;
  }

  return $self->{'regionIdent'};
}

#==============================================================================

=item sub merge_terrestrial_surface_conditions([$newValue])

 $value = $env_ctl->merge_terrestrial_surface_conditions($newValue);

Merge Terrestrial Surface Conditions.

This attribute specifies whether the terrestrial surface conditions found 
within this region should be merged with those of other regions within areas of 
overlap.
If this attribute is set to Use Last (0), the last Terrestrial Surface 
Conditions Control packet describing a region containing a given point will be 
used to determine the surface conditions at that point.

If this attribute is set to Merge (1), the surface conditions at any given 
point within the region are averaged with those of any other regions also 
containing that point.

Note: Regional surface conditions always take priority over global surface conditions.

    UseLast   0
    Merge     1

=cut

sub merge_terrestrial_surface_conditions() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'mergeTerrestrialSurfaceConditions'}    = $nv;
      $self->{'_bitfields1'} |= ($nv << 5) &0x20;
    } else {
      carp "merge_terrestrial_surface_conditions must be 0 (UseLast), or 1 (Merge).";
    }
  }

  return (($self->{'_bitfields1'} & 0x20) >> 5);
}

#==============================================================================

=item sub merge_maritime_surface_conditions([$newValue])

 $value = $env_ctl->merge_maritime_surface_conditions($newValue);

Merge Maritime Surface Conditions.

This attribute specifies whether the maritime surface conditions found within 
this region should be merged with those of other regions within areas of 
overlap.
If this attribute is set to Use Last (0), the last Maritime Surface Conditions 
Control packet (Section 4.1.13) describing a region containing a given point 
will be used to determine the surface conditions at that point.

If this attribute is set to Merge (1), the surface conditions at any given 
point within the region are averaged with those of any other regions also 
containing that point.

Note: Regional surface conditions always take priority over global surface conditions.

    UseLast   0
    Merge     1

=cut

sub merge_maritime_surface_conditions() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'mergeMaritimeSurfaceConditions'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "merge_maritime_surface_conditions must be 0 (UseLast), or 1 (Merge).";
    }
  }

  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub merge_aerosol_concentrations([$newValue])

 $value = $env_ctl->merge_aerosol_concentrations($newValue);

Merge Aerosol Concentrations.

This attribute specifies whether the concentrations of aerosols found within 
this region should be merged with those of other regions within areas of 
overlap.
If this attribute is set to Use Last (0), the last Weather Control packet 
describing a layer containing a given point will be used to determine the 
concentration of the specified aerosol at that point.

If this attribute is set to Merge (1), the aerosol concentrations within all 
weather layers containing a given point are combined (see Table 16).

Note: Weather layers within the same region will always be combined. Regional 
weather conditions always take priority over global weather conditions.

    UseLast   0
    Merge     1

=cut

sub merge_aerosol_concentrations() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'mergeAerosolConcentrations'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "merge_aerosol_concentrations must be 0 (UseLast), or 1 (Merge).";
    }
  }

  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub merge_weather_properties([$newValue])

 $value = $env_ctl->merge_weather_properties($newValue);

Merge Weather Properties

This attribute specifies whether atmospheric conditions within this region 
should be merged with those of other regions within areas of overlap.

If this attribute is set to Use Last (0), the last Weather Control packet 
describing a layer containing a given point will be used to determine the 
weather conditions at that point.

If this attribute is set to Merge (1), the atmospheric properties of all 
weather layers containing a given point are combined (see Table 16).

Note: Weather layers within the same region will always be combined. Regional 
weather conditions always take priority over global weather conditions.

    UseLast   0
    Merge     1

=cut

sub merge_weather_properties() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'mergeWeatherProperties'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "merge_weather_properties must be 0 (UseLast), or 1 (Merge).";
    }
  }

  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub region_state([$newValue])

 $value = $env_ctl->region_state($newValue);

Region State.

This attribute specifies whether the region should be active or destroyed. This 
attribute may be set to one of the following values:

Inactive – Any weather layers and surface conditions defined within the region 
are disabled regardless of their individual enable states.

Active – Any weather layers and surface conditions defined within the region 
are enabled according to their individual enable states.

Destroyed – The environmental region is permanently deleted, as are all weather 
layers and surface conditions assigned to the region.

    Inactive    0
    Active      1
    Destroyed   2

=cut

sub region_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'regionState'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x03;
    } else {
      carp "region_state must be 0 (Inactive), 1 (Active), or 2 (Destroyed).";
    }
  }

  return ($self->{'_bitfields1'} & 0x03);
}

#==============================================================================

=item sub latitude([$newValue])

 $value = $env_ctl->latitude($newValue);

Latitude.

This attribute specifies the geodetic latitude of the center of the rounded rectangle.

=cut

sub latitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-90) and ($nv<=90.0)) {
      $self->{'latitude'} = $nv;
    } else {
      carp "latitude must be from -90.0 to +90.0.";
    }
  }

  return $self->{'latitude'};
}

#==============================================================================

=item sub longitude([$newValue])

 $value = $env_ctl->longitude($newValue);

Longitude.

This attribute specifies the geodetic longitude of the center of the rounded rectangle.

=cut

sub longitude() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-180.0) and ($nv<=180.0)) {
      $self->{'longitude'} = $nv;
    } else {
      carp "longitude must be from -180.0 to +180.0.";
    }
  }

  return $self->{'longitude'};
}

#==============================================================================

=item sub size_x([$newValue])

 $value = $env_ctl->size_x($newValue);

Size X.

This attribute specifies the length, measured in meters, of the environmental 
region along its X axis at the geoid surface. This length does not include the 
width of the transition perimeter.

=cut

sub size_x() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv > 0.0) {
      $self->{'sizeX'} = $nv;
    } else {
      carp "size_x must be > 0.0.";
    }
  }

  return $self->{'sizeX'};
}

#==============================================================================

=item sub size_y([$newValue])

 $value = $env_ctl->size_y($newValue);

Size Y.

This attribute specifies the length, measured in meters, of the environmental 
region along its Y axis at the geoid surface. This length does not include the 
width of the transition perimeter.

=cut

sub size_y() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv > 0.0) {
      $self->{'sizeY'} = $nv;
    } else {
      carp "size_y must be > 0.0.";
    }
  }

  return $self->{'sizeY'};
}

#==============================================================================

=item sub corner_radius([$newValue])

 $value = $env_ctl->corner_radius($newValue);

Corner Radius.

This attribute specifies the radius, measured in meters, of the corner of the 
rounded rectangle. The smaller the radius, the “tighter” the corner. A value of 
0.0 produces a rectangle.

=cut

sub corner_radius() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv>=0.0) {
      $self->{'cornerRadius'} = $nv;
    } else {
      carp "corner_radius must be > 0.0.";
    }
  }

  return $self->{'cornerRadius'};
}

#==============================================================================

=item sub rotation([$newValue])

 $value = $env_ctl->rotation($newValue);

Rotation.

This attribute specifies the yaw angle, measured in degrees from true north, of 
the rounded rectangle.

=cut

sub rotation() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv>=-180.0) and ($nv<=180.0)) {
      $self->{'rotation'} = $nv;
    } else {
      carp "rotation must be from -180.0 to +180.0.";
    }
  }

  return $self->{'rotation'};
}

#==============================================================================

=item sub transition_perimeter([$newValue])

 $value = $env_ctl->transition_perimeter($newValue);

Transition Perimeter.

This attribute specifies the width, measured in meters, of the transition 
perimeter around the environmental region. This perimeter is a region through 
which the weather conditions are interpolated between those inside the 
environmental region and those immediately outside the perimeter.

=cut

sub transition_perimeter() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv>=0.0) {
      $self->{'transitionPerimeter'} = $nv;
    } else {
      carp "transition_perimeter must be >= 0.0.";
    }
  }

  return $self->{'transitionPerimeter'};
}

#==========================================================================

=item sub pack()

 $value = $env_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'regionIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused17, mergeTerrestrialSurfaceConditions, mergeMaritimeSurfaceConditions, mergeAerosolConcentrations, mergeWeatherProperties, and regionState.
        $self->{'_unused18'},
        $self->{'_unused19'},
        $self->{'latitude'},
        $self->{'longitude'},
        $self->{'sizeX'},
        $self->{'sizeY'},
        $self->{'cornerRadius'},
        $self->{'rotation'},
        $self->{'transitionPerimeter'},
        $self->{'_unused20'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $env_ctl->unpack();

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
  $self->{'regionIdent'}                         = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused17, mergeTerrestrialSurfaceConditions, mergeMaritimeSurfaceConditions, mergeAerosolConcentrations, mergeWeatherProperties, and regionState.
  $self->{'_unused18'}                           = $e;
  $self->{'_unused19'}                           = $f;
  $self->{'latitude'}                            = $g;
  $self->{'longitude'}                           = $h;
  $self->{'sizeX'}                               = $i;
  $self->{'sizeY'}                               = $j;
  $self->{'cornerRadius'}                        = $k;
  $self->{'rotation'}                            = $l;
  $self->{'transitionPerimeter'}                 = $m;
  $self->{'_unused20'}                           = $n;

  $self->{'mergeTerrestrialSurfaceConditions'}   = $self->merge_terrestrial_surface_conditions();
  $self->{'mergeMaritimeSurfaceConditions'}      = $self->merge_maritime_surface_conditions();
  $self->{'mergeAerosolConcentrations'}          = $self->merge_aerosol_concentrations();
  $self->{'mergeWeatherProperties'}              = $self->merge_weather_properties();
  $self->{'regionState'}                         = $self->region_state();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g,$j,$i,$k,$l,$m,$n,$o,$p);
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
