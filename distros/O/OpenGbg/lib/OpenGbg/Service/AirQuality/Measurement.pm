use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::AirQuality::Measurement;

# ABSTRACT: An air quality measurement
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use utf8;
use syntax 'qs';
use XML::Rabbit;
use DateTime::Format::HTTP;
use MooseX::AttributeShortcuts;
use Types::DateTime qw/DateTime/;

# any attributes/methods added here should also be 'handled' in GetLatestMeasurement.

has_xpath_value _starttime => './x:StartTime';
has_xpath_value _endtime => './x:StopTime';

has_xpath_value temperature      => './x:Weather/x:Temperature/x:Value';
has_xpath_value _temperature_unit => './x:Weather/x:Temperature/x:Unit';
has_xpath_value humidity      => './x:Weather/x:Humidity/x:Value';
has_xpath_value humidity_unit => './x:Weather/x:Humidity/x:Unit';
has_xpath_value _solar_insolation      => './x:Weather/x:SolarInsolation/x:Value';
has_xpath_value solar_insolation_unit => './x:Weather/x:SolarInsolation/x:Unit';
has_xpath_value air_pressure      => './x:Weather/x:AirPressure/x:Value';
has_xpath_value air_pressure_unit => './x:Weather/x:AirPressure/x:Unit';
has_xpath_value wind_speed      => './x:Weather/x:WindSpeed/x:Value';
has_xpath_value wind_speed_unit => './x:Weather/x:WindSpeed/x:Unit';
has_xpath_value wind_direction      => './x:Weather/x:WindDirection/x:Value';
has_xpath_value _wind_direction_unit => './x:Weather/x:WindDirection/x:Unit';
has_xpath_value _rainfall      => './x:Weather/x:RainFall/x:Value';
has_xpath_value rainfall_unit => './x:Weather/x:RainFall/x:Unit';

has_xpath_value total_index => './x:AirQuality/x:TotalIndex';

has_xpath_value no2 => './x:AirQuality/x:NO2/x:Value';
has_xpath_value _no2_unit => './x:AirQuality/x:NO2/x:Unit';
has_xpath_value no2_index => './x:AirQuality/x:NO2/x:Index';

has_xpath_value so2 => './x:AirQuality/x:SO2/x:Value';
has_xpath_value _so2_unit => './x:AirQuality/x:SO2/x:Unit';
has_xpath_value so2_index => './x:AirQuality/x:SO2/x:Index';

has_xpath_value o3 => './x:AirQuality/x:O3/x:Value';
has_xpath_value _o3_unit => './x:AirQuality/x:O3/x:Unit';
has_xpath_value o3_index => './x:AirQuality/x:O3/x:Index';

has_xpath_value pm10 => './x:AirQuality/x:PM10/x:Value';
has_xpath_value _pm10_unit => './x:AirQuality/x:PM10/x:Unit';
has_xpath_value pm10_index => './x:AirQuality/x:PM10/x:Index';

has_xpath_value co => './x:AirQuality/x:CO/x:Value';
has_xpath_value _co_unit => './x:AirQuality/x:CO/x:Unit';
has_xpath_value co_index => './x:AirQuality/x:CO/x:Index';

has_xpath_value nox => './x:AirQuality/x:NOx/x:Value';
has_xpath_value _nox_unit => './x:AirQuality/x:NOx/x:Unit';
has_xpath_value nox_index => './x:AirQuality/x:NOx/x:Index';

has_xpath_value pm2_5 => './x:AirQuality/x:PM2_5/x:Value';
has_xpath_value _pm2_5_unit => './x:AirQuality/x:PM2_5/x:Unit';
has_xpath_value pm2_5_index => './x:AirQuality/x:PM2_5/x:Index';


sub solar_insolation {
    my $self = shift;
    return length $self->_solar_insolation ? $self->_solar_insolation : 0;
}
sub rainfall {
    my $self = shift;
    return length $self->_rainfall ? $self->_rainfall : 0;
}
sub temperature_unit {
    my $self = shift;
    return $self->_temperature_unit eq '°C' ? 'degrees C' : $self->_temperature_unit;
}
sub wind_direction_unit {
    my $self = shift;
    return $self->_wind_direction_unit eq '°' ? 'degrees' : $self->_wind_direction_unit;
}

sub microutf_to_ascii {
    my $self = shift;
    my $unit = shift;

    return $self->_pm2_5_unit eq 'µg/m3' || $self->_pm2_5_unit eq 'ug/m3' ? 'microgram/m3' : $unit;
}

sub no2_unit {
    my $self = shift;
    return $self->microutf_to_ascii($self->_no2_unit);
}
sub so2_unit {
    my $self = shift;
    return $self->microutf_to_ascii($self->_so2_unit);
}
sub o3_unit {
    my $self = shift;
    return $self->microutf_to_ascii($self->_o3_unit);
}
sub co_unit {
    my $self = shift;
    return $self->microutf_to_ascii($self->_co_unit);
}
sub pm10_unit {
    my $self = shift;
    return $self->microutf_to_ascii($self->_pm10_unit);
}
sub nox_unit {
    my $self = shift;
    return $self->microutf_to_ascii($self->_nox_unit);
}
sub pm2_5_unit {
    my $self = shift;
    return $self->microutf_to_ascii($self->_pm2_5_unit);
}

sub index_to_levels {
    my $index = shift;
    return $index if !$index;
    return $index >= 3 ? 'very high levels'
         : $index >= 2 ? 'high levels'
         : $index >= 1 ? 'medium levels'
         :               'low levels'
         ;
}
sub total_levels {
    my $self = shift;
    return $self->index_to_levels($self->total_index);
}
sub no2_levels {
    my $self = shift;
    return $self->index_to_levels($self->no2_index);
}
sub so2_levels {
    my $self = shift;
    return $self->index_to_levels($self->so2_index);
}
sub o3_levels {
    my $self = shift;
    return $self->index_to_levels($self->o3_index);
}
sub co_levels {
    my $self = shift;
    return $self->index_to_levels($self->co_index);
}
sub pm10_levels {
    my $self = shift;
    return $self->index_to_levels($self->pm10_index);
}
sub nox_levels {
    my $self = shift;
    return $self->index_to_levels($self->nox_index);
}
sub pm2_5_levels {
    my $self = shift;
    return $self->index_to_levels($self->pm2_5_index);
}


has starttime => (
    is => 'ro',
    isa => DateTime,
    lazy => 1,
    builder => 1,
);

has endtime => (
    is => 'ro',
    isa => DateTime,
    lazy => 1,
    builder => 1,
);

sub _build_starttime {
    my $self = shift;
    return DateTime::Format::HTTP->parse_datetime($self->_starttime);
}
sub _build_endtime {
    my $self = shift;
    return DateTime::Format::HTTP->parse_datetime($self->_endtime);
}

sub to_text {
    my $self = shift;
    return sprintf "\n%s %s -- %s %s\n%s%s", $self->starttime->ymd('-'),
                                             $self->starttime->hms(':'),
                                             $self->endtime->ymd('-'),
                                             $self->endtime->hms(':'),
                                             $self->weather_to_text,
                                             $self->air_quality_to_text;
}

sub weather_to_text {
    my $self = shift;

    return sprintf qs{
        Temperature:         %7.2f %s
        Humiditiy:           %7.2f %s
        Solar insolation:    %7.2f %s
        Air pressure:        %7.2f %s
        Wind speed:          %7.2f %s
        Wind direction:      %7.2f %s
        Rainfall:            %7.2f %s
    },
    $self->temperature,
    $self->temperature_unit,
    $self->humidity,
    $self->humidity_unit,
    $self->solar_insolation,
    $self->solar_insolation_unit,
    $self->air_pressure,
    $self->air_pressure_unit,
    $self->wind_speed,
    $self->wind_speed_unit,
    $self->wind_direction,
    $self->wind_direction_unit,
    $self->rainfall,
    $self->rainfall_unit
    ;
}

sub air_quality_to_text {
    my $self = shift;

    no warnings 'numeric';
    return sprintf qs{
        Total index:                               [ %4s ] [ %-16s ]
        Nitrogen dioxide:    %7.2f %s  [ %4s ] [ %-16s ]
        Nitrogen oxides:     %7.2f %s  [ %4s ] [ %-16s ]
        Sulfur dioxide:      %7.2f %s  [ %4s ] [ %-16s ]
        Carbon monoxide:     %7.2f %s  [ %4s ] [ %-16s ]
        Ground level ozone:  %7.2f %s  [ %4s ] [ %-16s ]
        <10mm particulates:  %7.2f %s  [ %4s ] [ %-16s ]
        <2.5mm particulates: %7.2f %s  [ %4s ] [ %-16s ]
    },
    $self->total_index,
    $self->total_levels,
    $self->no2,
    $self->no2_unit,
    $self->no2_index,
    $self->no2_levels,
    $self->so2,
    $self->so2_unit,
    $self->so2_index,
    $self->so2_levels,
    $self->o3,
    $self->o3_unit,
    $self->o3_index,
    $self->o3_levels,
    $self->pm10,
    $self->pm10_unit,
    $self->pm10_index,
    $self->pm10_levels,
    $self->co,
    $self->co_unit,
    $self->co_index,
    $self->co_levels,
    $self->nox,
    $self->nox_unit,
    $self->nox_index,
    $self->nox_levels,
    $self->pm2_5,
    $self->pm2_5_unit,
    $self->pm2_5_index,
    $self->pm2_5_levels,
    ;
}

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 SYNOPSIS

    my $service = OpenGbg->new->air_quality;
    my $response = $service->get_latest_measurement;
    my $measurement = $response->measurement;

    printf '%5.2f %s' => $measurement->temperature, $measurement->temperature_unit;

=head1 WEATHER ATTRIBUTES

All of these attribues are decimal numbers.

For all weather attributes there is also a unit attribute (C<${attribute_name}_unit>) that returns a textual representation the unit.

=head2 temperature

The temperature (in degrees centigrade) during the measurement.

=head2 humidity

The humidity (in percent) during the measurement.

=head2 solar_insolation

The solar insolation (in Watts/square metre) during the measurement.

=head2 air_pressure

The air pressure (in hPa) during the measurement.

=head2 wind_speed

The wind speed (in metres/second) during the mesaurement.

=head2 wind_direction

The wind direction (in degrees) during the measurement.

=head2 rainfall

The rainfall (in mm) during the measurement.


=head1 AIR QUALITY ATTRIBUTES

All of these attribues are normally decimal numbers. Empty string or undef denotes missing information.

The unit for these attributes is microgram/cubic metre.

All air quality attributes also have these additional attributes:

C<${attribute_name}_unit> returns a textual representation the unit the value is given in.

C<${attribute_name}_index> returns a decimal number indicating the polution level for that particular attribute.

C<${attribute_name}_levels> is like the C<*_index> attribute, but in text. Values are C<low levels>, C<medium levels>, C<high levels>, C<very high levels>). Empty string/undef if the index is the empty string/undef.


B<Note:> The web service sometimes returns I<negative> values for some of these measurements.

=head2 total_index

The overall Air Quality Index. Calculated from some of the other indices.

=head2 co

The amount of carbon monoxide in the air.

=head2 o3

The amount of ground level ozone in the air.

=head2 no2

The amount of nitrogen dioxide in the air.

=head2 nox

The amount of nitrogen oxides in the air.

=head2 pm2_5

The amount of particulates (less than 2.5 micrometers) in the air.

=head2 pm10

The amount of particulates (less than 10 micrometers) in the air.

=head2 so2

The amount of sulfur dioxide in the air.

=head1 METHODS

=head2 to_text()

Returns a string with the station data in a table.

=cut

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGbg::Service::AirQuality::Measurement - An air quality measurement

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
