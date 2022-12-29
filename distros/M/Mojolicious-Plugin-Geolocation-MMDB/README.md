# Mojolicious::Plugin::Geolocation::MMDB

This Mojolicious plugin provides a helper that maps IPv4 and IPv6 addresses to
location information such as country and city names.

    use Mojolicious::Lite -signatures;

    plugin 'Geolocation::MMDB', {file => 'Country.mmdb'};

    get '/' => sub ($c) {
      my $location = $c->geolocation;
      my $country =
        eval { $location->{country}->{names}->{en} } // 'unknown location';
      $c->render(text => "Welcome visitor from $country");
    };

    app-start;

## DEPENDENCIES

Requires the Perl modules Mojolicious and IP::Geolocation::MMDB from CPAN.

Requires an IP to country, city or ASN database in the MaxMind DB file format
from [MaxMind](https://www.maxmind.com) or [DP-IP.com](https://db-ip.com/).

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Mojolicious::Plugin::Geolocation::MMDB

## LICENSE AND COPYRIGHT

Copyright (C) 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
