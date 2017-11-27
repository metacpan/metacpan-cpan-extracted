use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../";
use Test::More;
use t::scan::Util;

test(<<'END'); # CSSON/OpenGbg-0.1402/lib/OpenGbg/Service/AirQuality/Measurement.pm
use syntax 'qs';

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
END

done_testing;
