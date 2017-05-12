use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::AirQuality::GetLatestMeasurement;

# ABSTRACT: Get the latest air quality measurement
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use XML::Rabbit::Root;
use Types::Standard qw/Bool Str/;

has xml => (
    is => 'ro',
    isa => Str,
    required => 1,
);

add_xpath_namespace 'x' => 'TK.DevServer.Services.AirQualityService';

has measurement_called => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

sub measurement {
    my $self = shift;
    warn q{Deprecated attribute 'measurement' called} if !$self->measurement_called;
    $self->measurement_called(1);
    return $self->_measurement;
}

has_xpath_object _measurement => '/x:Measurement' => 'OpenGbg::Service::AirQuality::Measurement',
    handles => [qw/
        starttime
        endtime

        temperature
        temperature_unit
        humidity
        humidity_unit
        solar_insolation
        solar_insolation_unit
        air_pressure
        air_pressure_unit
        wind_speed
        wind_speed_unit
        wind_direction
        wind_direction_unit
        rainfall
        rainfall_unit

        total_index

        no2
        no2_unit
        no2_index

        so2
        so2_unit
        so2_index

        o3
        o3_unit
        o3_index

        pm10
        pm10_unit
        pm10_index

        co
        co_unit
        co_index

        nox
        nox_unit
        nox_index

        pm2_5
        pm2_5_unit
        pm2_5_index

        total_levels
        no2_levels
        so2_levels
        o3_levels
        co_levels
        pm10_levels
        nox_levels
        pm2_5_levels

        to_text
        weather_to_text
        air_quality_to_text
    /];

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::AirQuality::GetLatestMeasurement - Get the latest air quality measurement

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    my $service = OpenGbg->new->air_quality;
    my $measurement = $service->get_latest_measurement;

    print $measurement->temperature;

=head1 METHODS

See L<OpenGbg::Service::AirQuality::Measurement> for available methods and attributes.

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
