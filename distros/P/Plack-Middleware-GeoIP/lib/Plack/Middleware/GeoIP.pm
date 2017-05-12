package Plack::Middleware::GeoIP;
use strict;
use warnings;
use 5.008;
our $VERSION = 0.05;
use parent qw/Plack::Middleware/;
use Geo::IP;

use Plack::Util::Accessor qw( GeoIPDBFile GeoIPEnableUTF8 );

sub geoip_flag {
    my $self = shift;
    my $flag = shift;

    return GEOIP_MEMORY_CACHE if $flag eq 'MemoryCache';
    return GEOIP_CHECK_CACHE  if $flag eq 'CheckCache';
    return GEOIP_INDEX_CACHE  if $flag eq 'IndexCache';
    return GEOIP_MMAP_CACHE   if $flag eq 'MMapCache';
    return GEOIP_STANDARD;
}

sub prepare_app {
    my $self = shift;

    if (my $dbfiles = $self->GeoIPDBFile) {
        my @dbfiles = ref $dbfiles ? @{ $dbfiles } : ($dbfiles);
        foreach my $dbfile (@dbfiles) {
            my ($filename, $flag) = ref $dbfile ? @{ $dbfile } : ($dbfile, 'Standard');

            # combine flags
            my @flags = ref $flag ? @{ $flag } : ($flag);
            my $flags = GEOIP_STANDARD; 
            foreach my $f (@flags) {
                $flags |= $self->geoip_flag($f);
            }

            my $gi = Geo::IP->open($filename, $flags);
            $gi->set_charset(GEOIP_CHARSET_UTF8) if $self->GeoIPEnableUTF8;
            push @{ $self->{gips} }, $gi;
        }
    } else {
        my $gi = Geo::IP->new(GEOIP_STANDARD);
        push @{ $self->{gips} }, $gi;
    }
}

sub call {
    my $self = shift;
    my $env  = shift;

    my $ipaddr = $env->{REMOTE_ADDR};

    foreach my $gi (@{ $self->{gips} }) {
        my $type = $gi->database_edition;
        if (GEOIP_COUNTRY_EDITION == $type) {
            if (my $code = $gi->country_code_by_addr($ipaddr)) {
                $env->{GEOIP_COUNTRY_CODE}   = $code;
                $env->{GEOIP_COUNTRY_CODE3}  = $gi->country_code3_by_addr($ipaddr);
                $env->{GEOIP_COUNTRY_NAME}   = $gi->country_name_by_addr($ipaddr);
                $env->{GEOIP_CONTINENT_CODE} = $gi->continent_code_by_country_code($code);
            }
        } elsif (GEOIP_CITY_EDITION_REV0 == $type or GEOIP_CITY_EDITION_REV1 == $type) {
            if (my $record = $gi->record_by_addr($ipaddr)) {
                $env->{GEOIP_COUNTRY_CODE}   = $record->country_code;
                $env->{GEOIP_COUNTRY_CODE3}  = $record->country_code3;
                $env->{GEOIP_COUNTRY_NAME}   = $record->country_name;
                $env->{GEOIP_LATITUDE}       = $record->latitude;
                $env->{GEOIP_LONGITUDE}      = $record->longitude;
                $env->{GEOIP_CONTINENT_CODE} = $record->continent_code;
                $env->{GEOIP_TIME_ZONE}      = $record->time_zone   if $record->time_zone;
                $env->{GEOIP_REGION}         = $record->region      if $record->region;
                $env->{GEOIP_REGION_NAME}    = $record->region_name if $record->region and $record->region_name;
                $env->{GEOIP_CITY}           = $record->city        if $record->city;
                $env->{GEOIP_POSTAL_CODE}    = $record->postal_code if $record->postal_code;
                $env->{GEOIP_METRO_CODE}     = $record->metro_code  if $record->metro_code;
                $env->{GEOIP_AREA_CODE}      = $record->area_code   if $record->area_code;
            }
        }
    }

    return $self->app->($env);
}

1;

=head1 NAME

Plack::Middleware::GeoIP - Find country and city of origin of a web request

=head1 SYNOPSIS

  # with Plack::Middleware::RealIP
  enable 'Plack::Middleware::RealIP',
      header => 'X-Forwarded-For',
      trusted_proxy => [ qw(192.168.1.0/24 192.168.2.1) ];
  enable 'Plack::Middleware::GeoIP',
      GeoIPDBFile => [ '/path/to/GeoIP.dat', '/path/to/GeoIPCity.dat' ],
      GeoIPEnableUTF8 => 1;

=head1 DESCRIPTION

Plack::Middleware::GeoIP is a loose port of the Apache module
mod_geoip. It uses Geo::IP to lookup the country and city that a web
request originated from.

All requests are looked up and GEOIP_* variables are added to PSGI
environment hash. For improved performance, you may want to only enable
this middleware for specific URL's.

The following PSGI environment variables are set by this middleware:

GeoIP Country Edition:

GEOIP_COUNTRY_CODE, GEOIP_COUNTRY_CODE3, GEOIP_COUNTRY_NAME,
GEOIP_CONTINENT_CODE

GeoIP City Edition:

GEOIP_COUNTRY_CODE, GEOIP_COUNTRY_CODE3, GEOIP_COUNTRY_NAME,
GEOIP_CONTINENT_CODE, GEOIP_LATITUDE, GEOIP_LONGITUDE, GEOIP_TIME_ZONE,
GEOIP_REGION, GEOIP_REGION_NAME, GEOIP_CITY, GEOIP_POSTAL_CODE,
GEOIP_METRO_CODE, GEOIP_AREA_CODE

=head1 CONFIGURATION

=over 4

=item GeoIPDBFile

  GeoIPDBFile => '/path/to/GeoIP.dat'
  GeoIPDBFile => [ '/path/to/GeoIP.dat', '/path/to/GeoIPCity.dat' ]
  GeoIPDBFile => [ '/path/to/GeoIP.dat', [ '/path/to/GeoIPCity.dat', 'MemoryCache' ] ]
  GeoIPDBFile => [ '/path/to/GeoIP.dat', [ '/path/to/GeoIPCity.dat', [ qw(MemoryCache CheckCache) ] ] ]

Path to GeoIP data file. GeoIP flags may also be specified. Accepted
flags are Standard, MemoryCache, CheckCache, IndexCache, and MMapCache.

=item GeoIPEnableUTF8

  GeoIPEnableUTF8 => 1

Turn on utf8 characters for city names.

=back

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<mod_geoip|http://www.maxmind.com/app/mod_geoip>

L<Geo::IP>

=cut
