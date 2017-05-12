package Plack::Middleware::GeoIP2;
use strict;
use warnings;
use 5.008;
our $VERSION = 0.05;
use parent qw/Plack::Middleware/;
use GeoIP2::Database::Reader;
use Carp;

use Plack::Util::Accessor qw( GeoIP2DBFile GeoIP2Locales );

sub prepare_app {
    my $self = shift;

    my $locales = $self->GeoIP2Locales || ['en'];

    if (my $dbfiles = $self->GeoIP2DBFile) {
        my @dbfiles = ref $dbfiles ? @{ $dbfiles } : ($dbfiles);
        foreach my $dbfile (@dbfiles) {
            my $gi = GeoIP2::Database::Reader->new(
                file => $dbfile,
                locales => $locales,
            );
            push @{ $self->{gips} }, $gi;
        }
    }
    else {
        Carp::croak('GeoIP2 database not found!');
    }
}

sub call {
    my $self = shift;
    my $env  = shift;

    my $ipaddr = $env->{REMOTE_ADDR};

    foreach my $gi (@{ $self->{gips} }) {
        eval {
            my $record = $gi->country( ip => $ipaddr );
            $env->{GEOIP_COUNTRY_CODE} = $record->country->iso_code;
            $env->{GEOIP_COUNTRY_NAME} = $record->country->name;
            $env->{GEOIP_CONTINENT_CODE} = $record->continent->name;
        };
        if ($@) {
            $env->{GEOIP_COUNTRY_CODE} = 'ZZ';
            $env->{GEOIP_COUNTRY_NAME} = 'Unknown Country';
            $env->{GEOIP_CONTINENT_CODE} = 'Unknown Continent';
        }
    }

    return $self->app->($env);
}

1;

=head1 NAME

Plack::Middleware::GeoIP2 - Find country and city of origin of a web request

=head1 SYNOPSIS

  # with Plack::Middleware::RealIP
  enable 'Plack::Middleware::RealIP',
      header => 'X-Forwarded-For',
      trusted_proxy => [ qw(192.168.1.0/24 192.168.2.1) ];
  enable 'Plack::Middleware::GeoIP',
      GeoIP2DBFile => [ '/path/to/GeoLite2-Country.mmdb', '/path/to/GeoIP2-Country.mmdb' ];

=head1 DESCRIPTION

Plack::Middleware::GeoIP2 is a version of Plack::Middleware::GeoIP using
the more recent GeoIP2 library from MaxMind.

All requests are looked up and GEOIP_* variables are added to PSGI
environment hash. For improved performance, you may want to only enable
this middleware for specific URL's.

The following PSGI environment variables are set by this middleware:

GeoIP Country Edition:

GEOIP_COUNTRY_CODE, GEOIP_COUNTRY_NAME, GEOIP_CONTINENT_CODE

When REMOTE_ADDR is an invalid/unknown IP, this module will set 'ZZ',
'Unknown Country', and 'Unknown Continent' for the above variables.

=head1 CONFIGURATION

=over 4

=item GeoIPDBFile

  GeoIPDBFile => '/path/to/GeoIP.dat'
  GeoIPDBFile => [ '/path/to/GeoIP.dat', '/path/to/GeoIPCity.dat' ]

Path to GeoIP2 data files.

=item GeoIP2Locales

  GeoIP2Locales => [ 'en', 'de' ]

Array of locale names passed to GeoIP2, to localize GEOIP_COUNTRY_NAME.

=back

=head1 AUTHOR

Zak B. Elep E<lt>zakame@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<mod_geoip|http://www.maxmind.com/app/mod_geoip>

L<GeoIP2>

=cut
